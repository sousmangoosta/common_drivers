// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
/*
 * Copyright (c) 2019 Amlogic, Inc. All rights reserved.
 */

#include <linux/module.h>
#include <linux/thermal.h>
#include <linux/cpufreq.h>
#include <linux/err.h>
#include <linux/slab.h>
#include <linux/cpu.h>
#include <linux/amlogic/gpu_cooling.h>

static int gpufreqcd_id;
static DEFINE_MUTEX(cooling_gpufreq_lock);
static int dyn_coef = -1;
static int max_pp;
static struct device_node *np;

/* notify_table passes value to the gpuFREQ_ADJUST callback function. */
#define NOTIFY_INVALID NULL

void save_gpu_cool_para(int coef, struct device_node *n, int pp)
{
	if (dyn_coef == -1 && !np) {
		dyn_coef = coef;
		np = n;
		max_pp = pp;
	}
}

static void gpu_coolingdevice_id_get(int *id)
{
	mutex_lock(&cooling_gpufreq_lock);
	*id = gpufreqcd_id++;
	mutex_unlock(&cooling_gpufreq_lock);
}

static void gpu_coolingdevice_id_put(void)
{
	mutex_lock(&cooling_gpufreq_lock);
	gpufreqcd_id--;
	mutex_unlock(&cooling_gpufreq_lock);
}

/* gpufreq cooling device callback functions are defined below */

/**
 * gpufreq_get_max_state - callback function to get the max cooling state.
 * @cdev: thermal cooling device pointer.
 * @state: fill this variable with the max cooling state.
 *
 * Callback for the thermal cooling device to return the gpufreq
 * max cooling state.
 *
 * Return: 0 on success, an error code otherwise.
 */
static int gpufreq_get_max_state(struct thermal_cooling_device *cdev,
				 unsigned long *state)
{
	struct gpufreq_cooling_device *gpufreq_device = cdev->devdata;

	if (gpufreq_device->get_gpu_max_level)
		*state = (unsigned long)(gpufreq_device->get_gpu_max_level());
	pr_debug("default max state=%ld\n", *state);
	return 0;
}

/**
 * gpufreq_get_cur_state - callback function to get the current cooling state.
 * @cdev: thermal cooling device pointer.
 * @state: fill this variable with the current cooling state.
 *
 * Callback for the thermal cooling device to return the gpufreq
 * current cooling state.
 *
 * Return: 0 on success, an error code otherwise.
 */
static int gpufreq_get_cur_state(struct thermal_cooling_device *cdev,
				 unsigned long *state)
{
	struct gpufreq_cooling_device *gpufreq_device = cdev->devdata;
	unsigned long max_state = 0, temp = 0;

	/* *state = gpufreq_device->gpufreq_state; */
	gpufreq_get_max_state(cdev, &max_state);
	if (gpufreq_device->get_gpu_current_max_level) {
		temp = gpufreq_device->get_gpu_current_max_level();
		*state = ((max_state - 1) - temp);
		gpufreq_device->gpufreq_state = *state;
		pr_debug("current max state=%ld\n", *state);
	} else {
		return -EINVAL;
	}
	return 0;
}

/**
 * gpufreq_set_cur_state - callback function to set the current cooling state.
 * @cdev: thermal cooling device pointer.
 * @state: set this variable to the current cooling state.
 *
 * Callback for the thermal cooling device to change the gpufreq
 * current cooling state.
 *
 * Return: 0 on success, an error code otherwise.
 */
static int gpufreq_set_cur_state(struct thermal_cooling_device *cdev,
				 unsigned long state)
{
	struct gpufreq_cooling_device *gpufreq_device = cdev->devdata;
	unsigned long max_state = 0;
	int ret;

	pr_debug("state=%ld,gpufreq_device->gpufreq_state=%d\n",
		 state, gpufreq_device->gpufreq_state);
	/* if (gpufreq_device->gpufreq_state == state) */
		/* return 0; */
	gpufreq_device->gpufreq_state = state;
	ret = gpufreq_get_max_state(cdev, &max_state);

	if (WARN_ON(state >= max_state))
		return -EINVAL;
	state = max_state - 1 - state;

	pr_debug("state=%ld,gpufreq_device->gpufreq_state=%d\n",
		 state, gpufreq_device->gpufreq_state);
	if (state <= max_state) {
		if (gpufreq_device->set_gpu_freq_idx)
			gpufreq_device->set_gpu_freq_idx((unsigned int)state);
	}
	return 0;
}

/*
 * Simple mathematics model for gpu freq power:
 * power is linear with frequent with coefficient t_c, each GPU pp has
 * same frequent
 * We set: online PP to n_c;
 *         temperature coefficient to t_c;
 *         power to p_c;
 *         current running frequent to F(MHz)
 * We have:
 *     Power = n_c * t_c * F
 */
static int gpufreq_get_requested_power(struct thermal_cooling_device *cdev,
				       u32 *power)
{
	struct gpufreq_cooling_device *gf_dev = cdev->devdata;
	int freq, coef, pp;
	long freq_state, max_state = 0;
	int load;

	gpufreq_get_max_state(cdev, &max_state);
	freq_state = (max_state - 1 - gf_dev->gpufreq_state);
	freq = gf_dev->get_gpu_freq(freq_state);
	pp   = gf_dev->get_online_pp();
	coef = gf_dev->dyn_coeff;
	load = gf_dev->get_gpu_loading();
	*power = (freq * coef * pp) * load / 102400;
	return 0;
}

static int gpufreq_state2power(struct thermal_cooling_device *cdev,
			       unsigned long state, u32 *power)
{
	struct gpufreq_cooling_device *gf_dev = cdev->devdata;
	int freq;
	int coef = gf_dev->dyn_coeff;
	int pp;
	int full_power;
	long max_state = 0;

	/* assume max pp */
	gpufreq_get_max_state(cdev, &max_state);
	freq = gf_dev->get_gpu_freq(max_state - 1 - state);
	pp = gf_dev->max_pp;
	full_power = freq * coef * pp;

	/* round up */
	*power =  full_power / 1024 + ((full_power & 0x3ff) ? 1 : 0);

	return 0;
}

static int gpufreq_power2state(struct thermal_cooling_device *cdev,
			       u32 power, unsigned long *state)
{
	struct gpufreq_cooling_device *gf_dev = cdev->devdata;
	int freq;
	int coef;
	int pp;
	long max_state = 0;

	gpufreq_get_max_state(cdev, &max_state);
	pp   = gf_dev->max_pp;
	coef = gf_dev->dyn_coeff;
	freq = (power * 1024) / (coef * pp);

	*state = gf_dev->get_gpu_freq_level(freq);
	return 0;
}

/* Bind gpufreq callbacks to thermal cooling device ops */
static struct thermal_cooling_device_ops const gpufreq_cooling_ops = {
	.get_max_state = gpufreq_get_max_state,
	.get_cur_state = gpufreq_get_cur_state,
	.set_cur_state = gpufreq_set_cur_state,
	.state2power   = gpufreq_state2power,
	.power2state   = gpufreq_power2state,
	.get_requested_power = gpufreq_get_requested_power,
};

/**
 * gpufreq_cooling_register - function to create gpufreq cooling device.
 * @clip_gpus: gpumask of gpus where the frequency constraints will happen.
 *
 * This interface function registers the gpufreq cooling device with the name
 * "thermal-gpufreq-%x". This api can support multiple instances of gpufreq
 * cooling devices.
 *
 * Return: a valid struct thermal_cooling_device pointer on success,
 * on failure, it returns a corresponding ERR_PTR().
 */
struct gpufreq_cooling_device *gpufreq_cooling_alloc(void)
{
	struct gpufreq_cooling_device *gcdev;

	gcdev = kzalloc(sizeof(*gcdev), GFP_KERNEL);
	if (!gcdev)
		return ERR_PTR(-ENOMEM);
	memset(gcdev, 0, sizeof(*gcdev));
	if (np) {
		gcdev->np = np;
		gcdev->dyn_coeff = dyn_coef;
		gcdev->max_pp = max_pp;
	}
	return gcdev;
}
EXPORT_SYMBOL_GPL(gpufreq_cooling_alloc);

int gpufreq_cooling_register(struct gpufreq_cooling_device *gpufreq_dev)
{
	struct thermal_cooling_device *cool_dev;
	char dev_name[THERMAL_NAME_LENGTH];

	gpu_coolingdevice_id_get(&gpufreq_dev->id);
	snprintf(dev_name, sizeof(dev_name), "thermal-gpufreq-%d",
		 gpufreq_dev->id);
	gpufreq_dev->gpufreq_state = 0;

	cool_dev = thermal_of_cooling_device_register(gpufreq_dev->np,
						      dev_name,
						      gpufreq_dev,
						      &gpufreq_cooling_ops);
	if (!cool_dev) {
		gpu_coolingdevice_id_put();
		kfree(gpufreq_dev);
		return -EINVAL;
	}
	gpufreq_dev->cool_dev = cool_dev;

	return 0;
}
EXPORT_SYMBOL_GPL(gpufreq_cooling_register);

/**
 * gpufreq_cooling_unregister - function to remove gpufreq cooling device.
 * @cdev: thermal cooling device pointer.
 *
 * This interface function unregisters the "thermal-gpufreq-%x" cooling device.
 */
void gpufreq_cooling_unregister(struct thermal_cooling_device *cdev)
{
	struct gpufreq_cooling_device *gpufreq_dev;

	if (!cdev)
		return;

	gpufreq_dev = cdev->devdata;

	thermal_cooling_device_unregister(gpufreq_dev->cool_dev);
	gpu_coolingdevice_id_put();
	kfree(gpufreq_dev);
}
EXPORT_SYMBOL_GPL(gpufreq_cooling_unregister);

unsigned int (*gpu_freq_callback)(void) = NULL;
EXPORT_SYMBOL(gpu_freq_callback);

int register_gpu_freq_info(unsigned int (*fun)(void))
{
	if (fun)
		gpu_freq_callback = fun;

	return 0;
}
EXPORT_SYMBOL(register_gpu_freq_info);
