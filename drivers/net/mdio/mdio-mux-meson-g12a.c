// SPDX-License-Identifier: (GPL-2.0+ OR MIT)
/*
 * Copyright (c) 2019 Amlogic, Inc. All rights reserved.
 */

#include <linux/bitfield.h>
#include <linux/clk.h>
#include <linux/clk-provider.h>
#include <linux/device.h>
#include <linux/io.h>
#include <linux/iopoll.h>
#include <linux/mdio-mux.h>
#include <linux/module.h>
#include <linux/phy.h>
#include <linux/platform_device.h>

#if IS_ENABLED(CONFIG_AMLOGIC_ETH_PRIVE)
#include <linux/amlogic/aml_phy_debug.h>
void __iomem *phy_analog_config_addr;
EXPORT_SYMBOL_GPL(phy_analog_config_addr);
/*0 for 12nm, 1 for 22nm*/
unsigned int phy_pll_mode;
EXPORT_SYMBOL_GPL(phy_pll_mode);
#endif

#define ETH_PLL_STS		0x40
#define ETH_PLL_CTL0		0x44
#if IS_ENABLED(CONFIG_AMLOGIC_ETH_PRIVE)
#define  PLL_CTL0_LOCK_FLAG	BIT(31)
#endif
#define  PLL_CTL0_LOCK_DIG	BIT(30)
#define  PLL_CTL0_RST		BIT(29)
#define  PLL_CTL0_EN		BIT(28)
#define  PLL_CTL0_SEL		BIT(23)
#define  PLL_CTL0_N		GENMASK(14, 10)
#define  PLL_CTL0_M		GENMASK(8, 0)
#define  PLL_LOCK_TIMEOUT	1000000
#define  PLL_MUX_NUM_PARENT	2
#define ETH_PLL_CTL1		0x48
#define ETH_PLL_CTL2		0x4c
#define ETH_PLL_CTL3		0x50
#define ETH_PLL_CTL4		0x54
#define ETH_PLL_CTL5		0x58
#define ETH_PLL_CTL6		0x5c
#define ETH_PLL_CTL7		0x60

#define ETH_PHY_CNTL0		0x80
#define   EPHY_G12A_ID		0x33010180
#define ETH_PHY_CNTL1		0x84
#define  PHY_CNTL1_ST_MODE	GENMASK(2, 0)
#define  PHY_CNTL1_ST_PHYADD	GENMASK(7, 3)
#define   EPHY_DFLT_ADD		8
#define  PHY_CNTL1_MII_MODE	GENMASK(15, 14)
#define   EPHY_MODE_RMII	0x1
#define  PHY_CNTL1_CLK_EN	BIT(16)
#define  PHY_CNTL1_CLKFREQ	BIT(17)
#define  PHY_CNTL1_PHY_ENB	BIT(18)
#define ETH_PHY_CNTL2		0x88
#define  PHY_CNTL2_USE_INTERNAL	BIT(5)
#define  PHY_CNTL2_SMI_SRC_MAC	BIT(6)
#define  PHY_CNTL2_RX_CLK_EPHY	BIT(9)

#define MESON_G12A_MDIO_EXTERNAL_ID 0
#define MESON_G12A_MDIO_INTERNAL_ID 1

struct g12a_mdio_mux {
	bool pll_is_enabled;
	void __iomem *regs;
	void *mux_handle;
	struct clk *pclk;
	struct clk *pll;
#if IS_ENABLED(CONFIG_AMLOGIC_ETH_PRIVE)
	struct device *dev;
#endif
};

struct g12a_ephy_pll {
	void __iomem *base;
	struct clk_hw hw;
};

#if IS_ENABLED(CONFIG_AMLOGIC_ETH_PRIVE)
/*0 for 12nm, 1 for 22nm*/
unsigned int phy_pll_mode;
#endif

#define g12a_ephy_pll_to_dev(_hw)			\
	container_of(_hw, struct g12a_ephy_pll, hw)

static unsigned long g12a_ephy_pll_recalc_rate(struct clk_hw *hw,
					       unsigned long parent_rate)
{
	struct g12a_ephy_pll *pll = g12a_ephy_pll_to_dev(hw);
	u32 val, m, n;

	val = readl(pll->base + ETH_PLL_CTL0);
	m = FIELD_GET(PLL_CTL0_M, val);
	n = FIELD_GET(PLL_CTL0_N, val);

	return parent_rate * m / n;
}

static int g12a_ephy_pll_enable(struct clk_hw *hw)
{
	struct g12a_ephy_pll *pll = g12a_ephy_pll_to_dev(hw);
	u32 val = readl(pll->base + ETH_PLL_CTL0);

	/* Apply both enable an reset */
	val |= PLL_CTL0_RST | PLL_CTL0_EN;
	writel(val, pll->base + ETH_PLL_CTL0);

	/* Clear the reset to let PLL lock */
	val &= ~PLL_CTL0_RST;
	writel(val, pll->base + ETH_PLL_CTL0);

	/* Poll on the digital lock instead of the usual analog lock
	 * This is done because bit 31 is unreliable on some SoC. Bit
	 * 31 may indicate that the PLL is not lock even though the clock
	 * is actually running
	 */
#if IS_ENABLED(CONFIG_AMLOGIC_ETH_PRIVE)

	if (phy_pll_mode == 1) {
		return readl_poll_timeout(pll->base + ETH_PLL_CTL0, val,
				  val & PLL_CTL0_LOCK_FLAG, 0, PLL_LOCK_TIMEOUT);
	}
	return readl_poll_timeout(pll->base + ETH_PLL_CTL0, val,
				  val & PLL_CTL0_LOCK_DIG, 0, PLL_LOCK_TIMEOUT);
#else
	return readl_poll_timeout(pll->base + ETH_PLL_CTL0, val,
				  val & PLL_CTL0_LOCK_DIG, 0, PLL_LOCK_TIMEOUT);
#endif
}

static void g12a_ephy_pll_disable(struct clk_hw *hw)
{
	struct g12a_ephy_pll *pll = g12a_ephy_pll_to_dev(hw);
	u32 val;

	val = readl(pll->base + ETH_PLL_CTL0);
	val &= ~PLL_CTL0_EN;
	val |= PLL_CTL0_RST;
	writel(val, pll->base + ETH_PLL_CTL0);
}

static int g12a_ephy_pll_is_enabled(struct clk_hw *hw)
{
	struct g12a_ephy_pll *pll = g12a_ephy_pll_to_dev(hw);
	unsigned int val;

	val = readl(pll->base + ETH_PLL_CTL0);

	return (val & PLL_CTL0_LOCK_DIG) ? 1 : 0;
}

static int g12a_ephy_pll_init(struct clk_hw *hw)
{
	struct g12a_ephy_pll *pll = g12a_ephy_pll_to_dev(hw);

	/* Apply PLL HW settings */
	/*12nm*/

#if IS_ENABLED(CONFIG_AMLOGIC_ETH_PRIVE)
	if (phy_pll_mode == 0) {
		writel(0x29c0040a, pll->base + ETH_PLL_CTL0);
		writel(0x927e0000, pll->base + ETH_PLL_CTL1);
		writel(0xac5f49e5, pll->base + ETH_PLL_CTL2);
		writel(0x00000000, pll->base + ETH_PLL_CTL3);
		writel(0x00000000, pll->base + ETH_PLL_CTL4);
		writel(0x20200000, pll->base + ETH_PLL_CTL5);
		writel(0x0000c002, pll->base + ETH_PLL_CTL6);
		writel(0x00000023, pll->base + ETH_PLL_CTL7);
	}
	/*22nm*/
	if (phy_pll_mode == 1) {
		writel(0x608200a0, pll->base + ETH_PLL_CTL0);
		writel(0xea002000, pll->base + ETH_PLL_CTL1);
		writel(0x00000150, pll->base + ETH_PLL_CTL2);
		writel(0x00000000, pll->base + ETH_PLL_CTL3);
		writel(0x708200a0, pll->base + ETH_PLL_CTL0);
		usleep_range(100, 200);
		writel(0x508200a0, pll->base + ETH_PLL_CTL0);
		writel(0x00000110, pll->base + ETH_PLL_CTL2);
	}
#else

	writel(0x29c0040a, pll->base + ETH_PLL_CTL0);
	writel(0x927e0000, pll->base + ETH_PLL_CTL1);
	writel(0xac5f49e5, pll->base + ETH_PLL_CTL2);
	writel(0x00000000, pll->base + ETH_PLL_CTL3);
	writel(0x00000000, pll->base + ETH_PLL_CTL4);
	writel(0x20200000, pll->base + ETH_PLL_CTL5);
	writel(0x0000c002, pll->base + ETH_PLL_CTL6);
	writel(0x00000023, pll->base + ETH_PLL_CTL7);
#endif
	return 0;
}

static const struct clk_ops g12a_ephy_pll_ops = {
	.recalc_rate	= g12a_ephy_pll_recalc_rate,
	.is_enabled	= g12a_ephy_pll_is_enabled,
	.enable		= g12a_ephy_pll_enable,
	.disable	= g12a_ephy_pll_disable,
	.init		= g12a_ephy_pll_init,
};

static int g12a_enable_internal_mdio(struct g12a_mdio_mux *priv)
{
	int ret;
#if IS_ENABLED(CONFIG_AMLOGIC_ETH_PRIVE)
	void __iomem *tx_amp_src = NULL;
	struct device_node *np = priv->dev->of_node;
	unsigned int tx_amp_addr = 0;
	unsigned int st_mode = 0;
	unsigned int phy_mode = 0;
	unsigned int rx_R = 0;

	if (of_property_read_u32(np, "tx_amp_src", &tx_amp_addr) != 0)
		pr_info("no amp setting\n");

	if (tx_amp_addr != 0) {
		pr_info("tx_amp_addr %x\n", tx_amp_addr);
		tx_amp_src = devm_ioremap(priv->dev,
				(resource_size_t)tx_amp_addr, sizeof(resource_size_t));

		pr_info("txamp 0x%x\n", readl(tx_amp_src));
		if (((readl(tx_amp_src) & 0x3f) >> 4) & 0x3)
			tx_amp_bl2 = (readl(tx_amp_src) & 0x3f);
		else /*efuse not set use default*/
			tx_amp_bl2 = (0x180018 & 0x3f);

		/*default 0, 1 means voltage phy*/
		if (of_property_read_u32(np, "phy_mode", &phy_mode) == 0) {
			pr_info("phy_mode %d\n", phy_mode);
			voltage_phy = phy_mode;
			if (phy_mode) {
				/*bit[20:16] bit20 valid, bit[19:16] rx value*/
				rx_R = (readl(tx_amp_src) & 0x1f0000);
		//		rx_R = (0x180018 & 0x1f0000);
				if (rx_R >> 0x14) { /*bit20 is valid*/
					pr_info("ETH_RES_CTL %x\n", (((rx_R & 0xf0000) << 8)
							| 0xe0fe0000
							| (readl(priv->regs + ETH_PLL_CTL3)
								& 0xffff)));
					writel((((rx_R & 0xf0000) << 8) | 0xe0fe0000)
						| (readl(priv->regs + ETH_PLL_CTL3) & 0xffff),
						priv->regs + ETH_PLL_CTL3);
				} else { /*efuse not set use default value*/
					pr_info("no efuse setting use default\n");
					writel(0xe8fe0000, priv->regs + ETH_PLL_CTL3);
				}
			}
		}
	}

	if (of_property_read_u32(np, "st_mode", &st_mode) != 0) {
		pr_info("use default st_mode\n");
		st_mode = 7;
	}
#endif
	/* Enable the phy clock */
	if (!priv->pll_is_enabled) {
		ret = clk_prepare_enable(priv->pll);
		if (ret)
			return ret;
	}

	priv->pll_is_enabled = true;

	/* Initialize ephy control */
	writel(EPHY_G12A_ID, priv->regs + ETH_PHY_CNTL0);
	writel(FIELD_PREP(PHY_CNTL1_ST_MODE, st_mode) |
	       FIELD_PREP(PHY_CNTL1_ST_PHYADD, EPHY_DFLT_ADD) |
	       FIELD_PREP(PHY_CNTL1_MII_MODE, EPHY_MODE_RMII) |
	       PHY_CNTL1_CLK_EN |
	       PHY_CNTL1_CLKFREQ |
	       PHY_CNTL1_PHY_ENB,
	       priv->regs + ETH_PHY_CNTL1);

	writel(FIELD_PREP(PHY_CNTL1_ST_MODE, st_mode) |
	       FIELD_PREP(PHY_CNTL1_ST_PHYADD, EPHY_DFLT_ADD) |
	       FIELD_PREP(PHY_CNTL1_MII_MODE, EPHY_MODE_RMII) |
	       PHY_CNTL1_CLK_EN |
	       PHY_CNTL1_CLKFREQ,
	       priv->regs + ETH_PHY_CNTL1);

	writel(FIELD_PREP(PHY_CNTL1_ST_MODE, st_mode) |
	       FIELD_PREP(PHY_CNTL1_ST_PHYADD, EPHY_DFLT_ADD) |
	       FIELD_PREP(PHY_CNTL1_MII_MODE, EPHY_MODE_RMII) |
	       PHY_CNTL1_CLK_EN |
	       PHY_CNTL1_CLKFREQ |
	       PHY_CNTL1_PHY_ENB,
	       priv->regs + ETH_PHY_CNTL1);

	mdelay(10);

	writel(PHY_CNTL2_USE_INTERNAL |
	       PHY_CNTL2_SMI_SRC_MAC |
	       PHY_CNTL2_RX_CLK_EPHY,
	       priv->regs + ETH_PHY_CNTL2);

	return 0;
}

static int g12a_enable_external_mdio(struct g12a_mdio_mux *priv)
{
	/* Reset the mdio bus mux */
	writel_relaxed(0x0, priv->regs + ETH_PHY_CNTL2);

	/* Disable the phy clock if enabled */
	if (priv->pll_is_enabled) {
		clk_disable_unprepare(priv->pll);
		priv->pll_is_enabled = false;
	}

	return 0;
}

static int g12a_mdio_switch_fn(int current_child, int desired_child,
			       void *data)
{
	struct g12a_mdio_mux *priv = dev_get_drvdata(data);
	if (current_child == desired_child)
		return 0;

	switch (desired_child) {
	case MESON_G12A_MDIO_EXTERNAL_ID:
		return g12a_enable_external_mdio(priv);
	case MESON_G12A_MDIO_INTERNAL_ID:
		return g12a_enable_internal_mdio(priv);
	default:
		return -EINVAL;
	}
}

static const struct of_device_id g12a_mdio_mux_match[] = {
	{ .compatible = "amlogic,g12a-mdio-mux", },
	{},
};
MODULE_DEVICE_TABLE(of, g12a_mdio_mux_match);

static int g12a_ephy_glue_clk_register(struct device *dev)
{
	struct g12a_mdio_mux *priv = dev_get_drvdata(dev);
	const char *parent_names[PLL_MUX_NUM_PARENT];
	struct clk_init_data init;
	struct g12a_ephy_pll *pll;
	struct clk_mux *mux;
	struct clk *clk;
	char *name;
	int i;

	/* get the mux parents */
	for (i = 0; i < PLL_MUX_NUM_PARENT; i++) {
		char in_name[8];

		snprintf(in_name, sizeof(in_name), "clkin%d", i);
		clk = devm_clk_get(dev, in_name);
		if (IS_ERR(clk)) {
			if (PTR_ERR(clk) != -EPROBE_DEFER)
				dev_err(dev, "Missing clock %s\n", in_name);
			return PTR_ERR(clk);
		}

		parent_names[i] = __clk_get_name(clk);
	}

	/* create the input mux */
	mux = devm_kzalloc(dev, sizeof(*mux), GFP_KERNEL);
	if (!mux)
		return -ENOMEM;

	name = kasprintf(GFP_KERNEL, "%s#mux", dev_name(dev));
	if (!name)
		return -ENOMEM;

	init.name = name;
	init.ops = &clk_mux_ro_ops;
	init.flags = 0;
	init.parent_names = parent_names;
	init.num_parents = PLL_MUX_NUM_PARENT;

	mux->reg = priv->regs + ETH_PLL_CTL0;
	mux->shift = __ffs(PLL_CTL0_SEL);
	mux->mask = PLL_CTL0_SEL >> mux->shift;
	mux->hw.init = &init;

	clk = devm_clk_register(dev, &mux->hw);
	kfree(name);
	if (IS_ERR(clk)) {
		dev_err(dev, "failed to register input mux\n");
		return PTR_ERR(clk);
	}

	/* create the pll */
	pll = devm_kzalloc(dev, sizeof(*pll), GFP_KERNEL);
	if (!pll)
		return -ENOMEM;

	name = kasprintf(GFP_KERNEL, "%s#pll", dev_name(dev));
	if (!name)
		return -ENOMEM;

	init.name = name;
	init.ops = &g12a_ephy_pll_ops;
	init.flags = 0;
	parent_names[0] = __clk_get_name(clk);
	init.parent_names = parent_names;
	init.num_parents = 1;

	pll->base = priv->regs;
	pll->hw.init = &init;

	clk = devm_clk_register(dev, &pll->hw);
	kfree(name);
	if (IS_ERR(clk)) {
		dev_err(dev, "failed to register input mux\n");
		return PTR_ERR(clk);
	}

	priv->pll = clk;

	return 0;
}

static int g12a_mdio_mux_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct g12a_mdio_mux *priv;
	int ret;
#if IS_ENABLED(CONFIG_AMLOGIC_ETH_PRIVE)
	struct device_node *np = dev->of_node;
#endif
	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
	if (!priv)
		return -ENOMEM;

	platform_set_drvdata(pdev, priv);

	priv->regs = devm_platform_ioremap_resource(pdev, 0);
	if (IS_ERR(priv->regs))
		return PTR_ERR(priv->regs);

#if IS_ENABLED(CONFIG_AMLOGIC_ETH_PRIVE)
	phy_analog_config_addr = priv->regs;
	priv->dev = dev;
	if (of_property_read_u32(np, "phy_pll_mode", &phy_pll_mode) != 0)
		pr_debug("default as 12nm setting\n");
#endif
	priv->pclk = devm_clk_get(dev, "pclk");
	if (IS_ERR(priv->pclk)) {
		ret = PTR_ERR(priv->pclk);
		if (ret != -EPROBE_DEFER)
			dev_err(dev, "failed to get peripheral clock\n");
		return ret;
	}

	/* Make sure the device registers are clocked */
	ret = clk_prepare_enable(priv->pclk);
	if (ret) {
		dev_err(dev, "failed to enable peripheral clock");
		return ret;
	}

	/* Register PLL in CCF */
	ret = g12a_ephy_glue_clk_register(dev);
	if (ret)
		goto err;

	ret = mdio_mux_init(dev, dev->of_node, g12a_mdio_switch_fn,
			    &priv->mux_handle, dev, NULL);
	if (ret) {
		if (ret != -EPROBE_DEFER)
			dev_err(dev, "mdio multiplexer init failed: %d", ret);
		goto err;
	}

	return 0;

err:
	clk_disable_unprepare(priv->pclk);
	return ret;
}

static int g12a_mdio_mux_remove(struct platform_device *pdev)
{
	struct g12a_mdio_mux *priv = platform_get_drvdata(pdev);

	mdio_mux_uninit(priv->mux_handle);

	if (priv->pll_is_enabled)
		clk_disable_unprepare(priv->pll);

	clk_disable_unprepare(priv->pclk);

	return 0;
}

static struct platform_driver g12a_mdio_mux_driver = {
	.probe		= g12a_mdio_mux_probe,
	.remove		= g12a_mdio_mux_remove,
	.driver		= {
		.name	= "g12a-mdio_mux",
		.of_match_table = g12a_mdio_mux_match,
	},
};
module_platform_driver(g12a_mdio_mux_driver);

MODULE_DESCRIPTION("Amlogic G12a MDIO multiplexer driver");
MODULE_AUTHOR("Jerome Brunet <jbrunet@baylibre.com>");
MODULE_LICENSE("GPL v2");
