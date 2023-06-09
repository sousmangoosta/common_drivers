#!/bin/bash

function pre_defconfig_cmds() {
	export OUT_AMLOGIC_DIR=$(readlink -m ${COMMON_OUT_DIR}/amlogic)
	if [ "${ARCH}" = "arm" ]; then
		export PATH=${PATH}:/usr/bin/
	fi

	if [[ -z ${ANDROID_PROJECT} ]]; then
		local temp_file=`mktemp /tmp/config.XXXXXXXXXXXX`
		echo "CONFIG_AMLOGIC_SERIAL_MESON=y" > ${temp_file}
		echo "CONFIG_DEVTMPFS=y" >> ${temp_file}
		if [[ ${ARCH} == arm ]]; then
			KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${GKI_BASE_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG} ${temp_file}
		else
			if [[ ${GKI_CONFIG} == gki_20 ]]; then
				KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${GKI_BASE_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG} ${temp_file}
			elif [[ ${GKI_CONFIG} == gki_10 ]]; then
				KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${GKI_BASE_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG_GKI10} ${temp_file}
			elif [[ ${GKI_CONFIG} == gki_debug ]]; then
				KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${GKI_BASE_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG_GKI10} ${ROOT_DIR}/${FRAGMENT_CONFIG_DEBUG} ${temp_file}
			fi
		fi
		rm ${temp_file}
	else
		if [[ ${ARCH} == arm ]]; then
			KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${GKI_BASE_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG}
		else
			if [[ ${GKI_CONFIG} == gki_20 ]]; then
				if [[  -n ${CHECK_GKI_20} ]]; then
					local temp_file=`mktemp /tmp/config.XXXXXXXXXXXX`
					echo "CONFIG_STMMAC_ETH=n" > ${temp_file}
					KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${GKI_BASE_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG} ${temp_file}
					rm ${temp_file}
				else
					KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${GKI_BASE_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG}
				fi
			elif [[ ${GKI_CONFIG} == gki_10 ]]; then
				KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${GKI_BASE_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG_GKI10}
			elif [[ ${GKI_CONFIG} == gki_debug ]]; then
				KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${GKI_BASE_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG_GKI10} ${ROOT_DIR}/${FRAGMENT_CONFIG_DEBUG}
			fi
		fi
	fi

	if [[ -n ${UPGRADE_PROJECT} ]]; then
		if [[ ${ANDROID_VERSION} == r || ${ANDROID_VERSION} == R ]]; then
			KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG_UPGRADE_R}
		fi
		if [[ ${ANDROID_VERSION} == p || ${ANDROID_VERSION} == P ]]; then
			KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG_UPGRADE_P}
		fi
		if [[ ${ANDROID_VERSION} == s || ${ANDROID_VERSION} == S ]]; then
			KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG_UPGRADE_S}
		fi
		if [[ ${ANDROID_VERSION} == u || ${ANDROID_VERSION} == U ]]; then
			KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${FRAGMENT_CONFIG_UPGRADE_U}
		fi
	fi

	if [[ ${IN_BUILD_GKI_10} == 1 ]]; then
		local temp_file=`mktemp /tmp/config.XXXXXXXXXXXX`
		echo "CONFIG_MODULE_SIG_ALL=y" >> ${temp_file}
		KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${temp_file}
		rm ${temp_file}
	fi

	if [[ -n ${DEV_CONFIGS} ]]; then
		config_list=$(echo ${DEV_CONFIGS}|sed 's/+/ /g')
		#verify the extra config is in the right path and merge the config
		CONFIG_DIR=arch/${ARCH}/configs
		for config_name in ${config_list[@]}
		do
			if [[ -f ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/${CONFIG_DIR}/${config_name} ]]; then
				KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/${CONFIG_DIR}/${config_name}
			elif [[ -f ${config_name} ]]; then
				KCONFIG_CONFIG=${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${ROOT_DIR}/${KERNEL_DIR}/scripts/kconfig/merge_config.sh -m -r ${ROOT_DIR}/${KCONFIG_DEFCONFIG} ${config_name}
			else
				echo "ERROR: config file ${config_name} is not in the right path!!"
				exit
			fi
		done
	fi
}
export -f pre_defconfig_cmds

function post_defconfig_cmds() {
	rm ${ROOT_DIR}/${KCONFIG_DEFCONFIG}
}
export -f post_defconfig_cmds

function read_ext_module_config() {
	ALL_LINE=""
	while read LINE
	do
		if [[ $LINE != \#*  &&  $LINE != "" ]]; then
			ALL_LINE="$ALL_LINE"" ""$LINE"
		fi
	done < $1

	echo "${ALL_LINE}"
}

function autotest(){
	if [[ -d ${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/.git/hooks/ ]]; then
		if [[ ! -f ${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/.git/hooks/pre-commit ]]; then
			cp ${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/scripts/amlogic/pre-commit ${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/.git/hooks/pre-commit
			cp ${KERNEL_DIR}/scripts/amlogic/pre-commit ${KERNEL_DIR}/.git/hooks/pre-commit
			chmod +x ${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/.git/hooks/pre-commit
			chmod +x ${KERNEL_DIR}/.git/hooks/pre-commit
		fi
	fi
}

function read_ext_module_predefine() {
	PRE_DEFINE=""

	for y_config in `cat $1 | grep "^CONFIG_.*=y" | sed 's/=y//'`; do
		PRE_DEFINE="$PRE_DEFINE"" -D"${y_config}
	done

	for m_config in `cat $1 | grep "^CONFIG_.*=m" | sed 's/=m//'`; do
		PRE_DEFINE="$PRE_DEFINE"" -D"${m_config}_MODULE
	done

	echo "${PRE_DEFINE}"
}

top_ext_drivers=top_ext_drivers
function prepare_module_build() {
	local temp_file=`mktemp /tmp/kernel.XXXXXXXXXXXX`
	if [[ ! `grep "CONFIG_AMLOGIC_IN_KERNEL_MODULES=y" ${ROOT_DIR}/${FRAGMENT_CONFIG}` ]]; then
		sed 's:#.*$::g' ${ROOT_DIR}/${FRAGMENT_CONFIG} | sed '/^$/d' | sed 's/^[ ]*//' | sed 's/[ ]*$//' > ${temp_file}
		GKI_EXT_KERNEL_MODULE_CONFIG=$(read_ext_module_config ${temp_file})
		GKI_EXT_KERNEL_MODULE_PREDEFINE=$(read_ext_module_predefine ${temp_file})
		export GKI_EXT_KERNEL_MODULE_CONFIG GKI_EXT_KERNEL_MODULE_PREDEFINE
	fi

	for ext_module_config in ${EXT_MODULES_CONFIG}; do
		sed 's:#.*$::g' ${ROOT_DIR}/${ext_module_config} | sed '/^$/d' | sed 's/^[ ]*//' | sed 's/[ ]*$//' > ${temp_file}
		GKI_EXT_MODULE_CONFIG=$(read_ext_module_config ${temp_file})
		GKI_EXT_MODULE_PREDEFINE=$(read_ext_module_predefine ${temp_file})
	done
	export GKI_EXT_MODULE_CONFIG GKI_EXT_MODULE_PREDEFINE
	echo GKI_EXT_MODULE_CONFIG=${GKI_EXT_MODULE_CONFIG}
	echo GKI_EXT_MODULE_PREDEFINE=${GKI_EXT_MODULE_PREDEFINE}

	if [[ ${TOP_EXT_MODULE_COPY_BUILD} -eq "1" ]]; then
		if [[ -d ${top_ext_drivers} ]]; then
			rm -rf ${top_ext_drivers}
		fi
		mkdir -p ${top_ext_drivers}
	fi

	if [[ ${AUTO_ADD_EXT_SYMBOLS} -eq "1" ]]; then
		extra_symbols="KBUILD_EXTRA_SYMBOLS +="
	fi
	ext_modules=
	for ext_module in ${EXT_MODULES}; do
		module_abs_path=`readlink -e ${ext_module}`
		module_rel_path=$(rel_path ${module_abs_path} ${ROOT_DIR})
		if [[ ${TOP_EXT_MODULE_COPY_BUILD} -eq "1" ]]; then
			if [[ `echo ${module_rel_path} | grep "\.\.\/"` ]]; then
				cp -rf ${module_abs_path} ${top_ext_drivers}
				module_rel_path=${top_ext_drivers}/${module_abs_path##*/}
			fi
		fi
		ext_modules="${ext_modules} ${module_rel_path}"
	done

	for ext_module_path in ${EXT_MODULES_PATH}; do
		sed 's:#.*$::g' ${ROOT_DIR}/${ext_module_path} | sed '/^$/d' | sed 's/^[ ]*//' | sed 's/[ ]*$//' > ${temp_file}
		while read LINE
		do
			module_abs_path=`readlink -e ${LINE}`
			module_rel_path=$(rel_path ${module_abs_path} ${ROOT_DIR})
			if [[ ${TOP_EXT_MODULE_COPY_BUILD} -eq "1" ]]; then
				if [[ `echo ${module_rel_path} | grep "\.\.\/"` ]]; then
					cp -rf ${module_abs_path} ${top_ext_drivers}
					module_rel_path=${top_ext_drivers}/${module_abs_path##*/}
				fi
			fi
			ext_modules="${ext_modules} ${module_rel_path}"

		done < ${temp_file}
	done
	EXT_MODULES=${ext_modules}

	local flag=0
	if [[ ${AUTO_ADD_EXT_SYMBOLS} -eq "1" ]]; then
		for ext_module in ${EXT_MODULES}; do
			ext_mod_rel=$(rel_path ${ext_module} ${KERNEL_DIR})
			if [[ ${flag} -eq "1" ]]; then
				sed -i "/# auto add KBUILD_EXTRA_SYMBOLS start/,/# auto add KBUILD_EXTRA_SYMBOLS end/d" ${ext_module}/Makefile
				sed -i "2 i # auto add KBUILD_EXTRA_SYMBOLS end" ${ext_module}/Makefile
				sed -i "2 i ${extra_symbols}" ${ext_module}/Makefile
				sed -i "2 i # auto add KBUILD_EXTRA_SYMBOLS start" ${ext_module}/Makefile
				echo "${ext_module}/Makefile add: ${extra_symbols}"
			fi
			extra_symbols="${extra_symbols} ${ext_mod_rel}/Module.symvers"
			flag=1
		done
	fi

	export EXT_MODULES
	echo EXT_MODULES=${EXT_MODULES}

	rm ${temp_file}
}
export -f prepare_module_build

function extra_cmds() {
	echo "========================================================"
	echo " Running extra build command(s):"

	if [[ ${AUTO_ADD_EXT_SYMBOLS} -eq "1" ]]; then
		for ext_module in ${EXT_MODULES}; do
			sed -i "/# auto add KBUILD_EXTRA_SYMBOLS start/,/# auto add KBUILD_EXTRA_SYMBOLS end/d" ${ext_module}/Makefile
		done
	fi

	if [[ ${TOP_EXT_MODULE_COPY_BUILD} -eq "1" ]]; then
		if [[ -d ${top_ext_drivers} ]]; then
			rm -rf ${top_ext_drivers}
		fi
	fi

	for FILE in ${FILES}; do
		if [[ "${FILE}" =~ \.dtbo ]]  && \
			[ -n "${DTS_EXT_DIR}" ] && [ -f "${OUT_DIR}/${DTS_EXT_DIR}/${FILE}" ] ; then
			MKDTIMG_DTBOS="${MKDTIMG_DTBOS} ${DIST_DIR}/${FILE}"
		fi
	done
	export MKDTIMG_DTBOS

	set +x
	modules_install
	set -x

	local src_dir=$(echo ${MODULES_STAGING_DIR}/lib/modules/*)
	pushd ${src_dir}
	cp modules.order modules_order.back
	: > modules.order
	set +x
	while read LINE
	do
		find -name ${LINE} >> modules.order
	done < ${OUT_AMLOGIC_DIR}/modules/modules.order
	set -x
	sed -i "s/^\.\///" modules.order
	: > ${OUT_AMLOGIC_DIR}/ext_modules/ext_modules.order
	ext_modules=
	for ext_module in ${EXT_MODULES}; do
		if [[ ${ext_module} =~ "../" ]]; then
			ext_module_old=${ext_module}
			ext_module=${ext_module//\.\.\//}
			ext_dir=$(dirname ${ext_module})
			[[ -d extra/${ext_module} ]] && rm -rf extra/${ext_dir}
			mkdir -p extra/${ext_dir}
			cp -rf extra/${ext_module_old} extra/${ext_dir}

			ext_modules_order_file=$(ls extra/${ext_module}/modules.order.*)
			ext_dir_top=${ext_module%/*}
			sed -i "s/\.\.\///g" ${ext_modules_order_file}
			cat ${ext_modules_order_file} >> modules.order
			cat ${ext_modules_order_file} | awk -F/ '{print $NF}' >> ${OUT_AMLOGIC_DIR}/ext_modules/ext_modules.order
			: > ${ext_modules_order_file}
		else
			ext_modules_order_file=$(ls extra/${ext_module}/modules.order.*)
			cat ${ext_modules_order_file} >> modules.order
			cat ${ext_modules_order_file} | awk -F/ '{print $NF}' >> ${OUT_AMLOGIC_DIR}/ext_modules/ext_modules.order
			: > ${ext_modules_order_file}
		fi
		ext_modules="${ext_modules} ${ext_module}"
	done
	EXT_MODULES=${ext_modules}
	echo EXT_MODULES=${EXT_MODULES}
	export EXT_MODULES

	head -n ${ramdisk_last_line} modules.order > vendor_boot_modules
	file_last_line=`sed -n "$=" modules.order`
	let line=${file_last_line}-${ramdisk_last_line}
	tail -n ${line} modules.order > vendor_dlkm_modules
	export MODULES_LIST=${src_dir}/vendor_boot_modules
	if [[ "${ARCH}" = "arm64" && -z ${FAST_BUILD} ]]; then
		export VENDOR_DLKM_MODULES_LIST=${src_dir}/vendor_dlkm_modules
	fi

	popd

	if [[ -z ${ANDROID_PROJECT} ]] && [[ -d ${OUT_DIR}/${DTS_EXT_DIR} ]]; then
		FILES="$FILES `ls ${OUT_DIR}/${DTS_EXT_DIR}`"
	fi

	if [[ -f ${KERNEL_BUILD_VAR_FILE} ]]; then
		: > ${KERNEL_BUILD_VAR_FILE}
		echo "KERNEL_DIR=${KERNEL_DIR}" >>  ${KERNEL_BUILD_VAR_FILE}
		echo "COMMON_OUT_DIR=${COMMON_OUT_DIR}" >>  ${KERNEL_BUILD_VAR_FILE}
		echo "OUT_DIR=${OUT_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "DIST_DIR=${DIST_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "OUT_AMLOGIC_DIR=${OUT_AMLOGIC_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "MODULES_STAGING_DIR=${MODULES_STAGING_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "MODULES_PRIVATE_DIR=${MODULES_PRIVATE_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "INITRAMFS_STAGING_DIR=${INITRAMFS_STAGING_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "SYSTEM_DLKM_STAGING_DIR=${SYSTEM_DLKM_STAGING_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "VENDOR_DLKM_STAGING_DIR=${VENDOR_DLKM_STAGING_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "MKBOOTIMG_STAGING_DIR=${MKBOOTIMG_STAGING_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "DIST_GKI_DIR=${DIST_GKI_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "FULL_KERNEL_VERSION=${FULL_KERNEL_VERSION}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "GKI_MODULES_LOAD_WHITE_LIST=\"${GKI_MODULES_LOAD_WHITE_LIST[*]}\"" >> ${KERNEL_BUILD_VAR_FILE}
		echo "BAZEL=${BAZEL}" >> ${KERNEL_BUILD_VAR_FILE}
	fi

	for module_path in ${PREBUILT_MODULES_PATH}; do
		find ${module_path} -type f -name "*.ko" -exec cp {} ${DIST_DIR} \;
	done
}
export -f extra_cmds

function bazel_extra_cmds() {
	modules_install

	if [[ -f ${KERNEL_BUILD_VAR_FILE} ]]; then
		: > ${KERNEL_BUILD_VAR_FILE}
		echo "KERNEL_DIR=${KERNEL_DIR}" >>  ${KERNEL_BUILD_VAR_FILE}
		echo "COMMON_OUT_DIR=${COMMON_OUT_DIR}" >>  ${KERNEL_BUILD_VAR_FILE}
		echo "DIST_DIR=${DIST_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "OUT_AMLOGIC_DIR=${OUT_AMLOGIC_DIR}" >> ${KERNEL_BUILD_VAR_FILE}
		echo "GKI_MODULES_LOAD_WHITE_LIST=\"${GKI_MODULES_LOAD_WHITE_LIST[*]}\"" >> ${KERNEL_BUILD_VAR_FILE}
		echo "BAZEL=${BAZEL}" >> ${KERNEL_BUILD_VAR_FILE}
	fi

	if [[ ${GKI_CONFIG} != gki_20 ]]; then
		[[ -f ${DIST_DIR}/system_dlkm_staging_archive_back.tar.gz ]] && rm -f ${DIST_DIR}/system_dlkm_staging_archive_back.tar.gz
		mv ${DIST_DIR}/system_dlkm_staging_archive.tar.gz ${DIST_DIR}/system_dlkm_staging_archive_back.tar.gz
		[[ -d ${DIST_DIR}/system_dlkm_gki10 ]] && rm -rf ${DIST_DIR}/system_dlkm_gki10
		mkdir ${DIST_DIR}/system_dlkm_gki10
		pushd ${DIST_DIR}/system_dlkm_gki10
		tar zxf ${DIST_DIR}/system_dlkm_staging_archive_back.tar.gz
		find -name "*.ko" | while read module; do
			module_name=${module##*/}
			if [[ ! `grep "/${module_name}" ${DIST_DIR}/system_dlkm.modules.load` ]]; then
				rm -f ${module}
			fi
		done
		tar czf ${DIST_DIR}/system_dlkm_staging_archive.tar.gz lib
		popd
		rm -rf ${DIST_DIR}/system_dlkm_gki10
	fi
}

export -f bazel_extra_cmds

function mod_probe() {
	local ko=$1
	local loop
	for loop in `grep "^$ko:" modules.dep | sed 's/.*://'`; do
		mod_probe $loop
		echo insmod $loop >> __install.sh
	done
}

function mod_probe_recovery() {
	local ko=$1
	local loop
	for loop in `grep "^$ko:" modules_recovery.dep | sed 's/.*://'`; do
		mod_probe_recovery $loop
		echo insmod $loop >> __install_recovery.sh
	done
}

function adjust_sequence_modules_loading() {
	if [[ -n $1 ]]; then
		chips=$1
	fi

	source ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/scripts/amlogic/modules_sequence_list
	cp modules.dep modules.dep.temp

	soc_module=()
	for chip in ${chips[@]}; do
		chip_module=`ls amlogic-*-soc-${chip}.ko`
		soc_module=(${soc_module[@]} ${chip_module[@]})
	done
	echo soc_module=${soc_module[*]}

	delete_soc_module=()
	if [[ ${#soc_module[@]} == 0 ]]; then
		echo "Use all soc module"
	else
		for module in `ls amlogic-*-soc-*`; do
			if [[ ! "${soc_module[@]}" =~ "${module}" ]] ; then
				echo Delete soc module: ${module}
				sed -n "/${module}:/p" modules.dep.temp
				sed -i "/${module}:/d" modules.dep.temp
				delete_soc_module=(${delete_soc_module[@]} ${module})
			fi
		done
		echo delete_soc_module=${delete_soc_module[*]}
	fi

	if [[ -n ${CLK_SOC_MODULE} ]]; then
		delete_clk_soc_modules=()
		for module in `ls amlogic-clk-soc-*`; do
			if [[ "${CLK_SOC_MODULE}" != "${module}" ]] ; then
				echo Delete clk soc module: ${module}
				sed -n "/${module}:/p" modules.dep.temp
				sed -i "/${module}:/d" modules.dep.temp
				delete_clk_soc_modules=(${delete_clk_soc_modules[@]} ${module})
			fi
		done
		echo delete_clk_soc_modules=${delete_clk_soc_modules[*]}
	fi

	if [[ -n ${PINCTRL_SOC_MODULE} ]]; then
		delete_pinctrl_soc_modules=()
		for module in `ls amlogic-pinctrl-soc-*`; do
			if [[ "${PINCTRL_SOC_MODULE}" != "${module}" ]] ; then
				echo Delete pinctrl soc module: ${module}
				sed -n "/${module}:/p" modules.dep.temp
				sed -i "/${module}:/d" modules.dep.temp
				delete_pinctrl_soc_modules=(${delete_pinctrl_soc_modules[@]} ${module})
			fi
		done
		echo delete_pinctrl_soc_modules=${delete_pinctrl_soc_modules[*]}
	fi

	in_line_i=a
	delete_type_modules=()
	echo "TYPE_MODULE_SELECT_MODULE=${TYPE_MODULE_SELECT_MODULE}"
	mkdir temp_dir
	cd temp_dir
	in_temp_dir=y
	for element in ${TYPE_MODULE_SELECT_MODULE}; do
		if [[ ${in_temp_dir} = y ]]; then
			cd ../
			rm -r temp_dir
			in_temp_dir=
		fi
		if [[ ${in_line_i} = a ]]; then
			in_line_i=b
			type_module=${element}
			select_modules_i=0
			select_modules_count=
			select_modules=
		elif [[ ${in_line_i} = b ]]; then
			in_line_i=c
			select_modules_count=${element}
		else
			let select_modules_i+=1
			select_modules="${select_modules} ${element}"
			if [[ ${select_modules_i} -eq ${select_modules_count} ]]; then
				in_line_i=a
				echo type_module=$type_module select_modules=$select_modules
				for module in `ls ${type_module}`; do
					dont_delete_module=0
					for select_module in ${select_modules}; do
						if [[ "${select_module}" == "${module}" ]] ; then
							dont_delete_module=1
							break;
						fi
					done
					if [[ ${dont_delete_module} != 1 ]]; then
						echo Delete module: ${module}
						sed -n "/${module}:/p" modules.dep.temp
						sed -i "/${module}:/d" modules.dep.temp
						delete_type_modules=(${delete_type_modules[@]} ${module})
					fi
				done
				echo delete_type_modules=${delete_type_modules[*]}
			fi
		fi
	done
	if [[ -n ${in_temp_dir} ]]; then
		cd ../
		rm -r temp_dir
	fi

	black_modules=()
	mkdir service_module
	echo  MODULES_SERVICE_LOAD_LIST=${MODULES_SERVICE_LOAD_LIST[@]}
	BLACK_AND_SERVICE_LIST=(${MODULES_LOAD_BLACK_LIST[@]} ${MODULES_SERVICE_LOAD_LIST[@]})
	echo ${BLACK_AND_SERVICE_LIST[@]}
	for module in ${BLACK_AND_SERVICE_LIST[@]}; do
		modules=`ls ${module}*`
		black_modules=(${black_modules[@]} ${modules[@]})
	done
	if [[ ${#black_modules[@]} == 0 ]]; then
		echo "black_modules is null, don't delete modules, MODULES_LOAD_BLACK_LIST=${MODULES_LOAD_BLACK_LIST[*]}"
	else
		echo black_modules=${black_modules[*]}
		for module in ${black_modules[@]}; do
			echo Delete module: ${module}
			sed -n "/${module}:/p" modules.dep.temp
			sed -i "/${module}:/d" modules.dep.temp
		done
	fi

	GKI_MODULES_LOAD_BLACK_LIST=()
	if [[ "${FULL_KERNEL_VERSION}" != "common13-5.15" ]]; then
		gki_modules_temp_file=`mktemp /tmp/config.XXXXXXXXXXXX`
		if [[ ${BAZEL} == "1" ]]; then
			cp $DIST_DIR/system_dlkm.modules.load ${gki_modules_temp_file}
		else
			rm -f ${gki_modules_temp_file}
			cat ${ROOT_DIR}/${KERNEL_DIR}/modules.bzl |grep ko | while read LINE
			do
				echo $LINE | sed 's/^[^"]*"//' | sed 's/".*$//' >> ${gki_modules_temp_file}
			done
		fi

		for module in ${GKI_MODULES_LOAD_WHITE_LIST[@]}; do
			sed -i "/\/${module}/d" ${gki_modules_temp_file}
		done

		for module in `cat ${gki_modules_temp_file}`; do
			module=${module##*/}
			GKI_MODULES_LOAD_BLACK_LIST[${#GKI_MODULES_LOAD_BLACK_LIST[*]}]=${module}
		done
		rm -f ${gki_modules_temp_file}

		for module in ${GKI_MODULES_LOAD_BLACK_LIST[@]}; do
			echo Delete module: ${module}
			sed -n "/${module}:/p" modules.dep.temp
			sed -i "/${module}:/d" modules.dep.temp
		done
	fi

	cat modules.dep.temp | cut -d ':' -f 2 > modules.dep.temp1
	delete_modules=(${delete_soc_module[@]} ${delete_clk_soc_modules[@]} ${delete_pinctrl_soc_modules[@]} ${delete_type_modules[@]} ${black_modules[@]} ${GKI_MODULES_LOAD_BLACK_LIST[@]})
	for module in ${delete_modules[@]}; do
		if [[ ! `ls $module` ]]; then
			continue
		fi
		match=`sed -n "/${module}/=" modules.dep.temp1`
		for match in ${match[@]}; do
			match_count=(${match_count[@]} $match)
		done
		if [[ ${#match_count[@]} != 0 ]]; then
			echo "Error ${#match_count[@]} modules depend on ${module}, please modify:"
			echo ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/scripts/amlogic/modules_sequence_list:MODULES_LOAD_BLACK_LIST
			exit
		fi
		if [[ -n ${ANDROID_PROJECT} ]]; then
			for service_module_temp in ${MODULES_SERVICE_LOAD_LIST[@]}; do
				if [[ ${module} = ${service_module_temp} ]]; then
					mv ${module} service_module
				fi
			done
		fi
		rm -f ${module}
	done
	rm -f modules.dep.temp1
	touch modules.dep.temp1

	for module in ${RAMDISK_MODULES_LOAD_LIST[@]}; do
		echo RAMDISK_MODULES_LOAD_LIST: $module
		sed -n "/${module}:/p" modules.dep.temp
		sed -n "/${module}:/p" modules.dep.temp >> modules.dep.temp1
		sed -i "/${module}:/d" modules.dep.temp
		sed -n "/${module}.*\.ko:/p" modules.dep.temp
		sed -n "/${module}.*\.ko:/p" modules.dep.temp >> modules.dep.temp1
		sed -i "/${module}.*\.ko:/d" modules.dep.temp
	done

	if [[ -n ${ANDROID_PROJECT} ]]; then
		cp modules.dep.temp modules_recovery.dep.temp
		cp modules.dep.temp1 modules_recovery.dep.temp1
	fi

	for module in ${VENDOR_MODULES_LOAD_FIRST_LIST[@]}; do
		echo VENDOR_MODULES_LOAD_FIRST_LIST: $module
		sed -n "/${module}:/p" modules.dep.temp
		sed -n "/${module}:/p" modules.dep.temp >> modules.dep.temp1
		sed -i "/${module}:/d" modules.dep.temp
		sed -n "/${module}.*\.ko:/p" modules.dep.temp
		sed -n "/${module}.*\.ko:/p" modules.dep.temp >> modules.dep.temp1
		sed -i "/${module}.*\.ko:/d" modules.dep.temp
	done

	if [ -f modules.dep.temp2 ]; then
		rm modules.dep.temp2
	fi
	touch modules.dep.temp2
	for module in ${VENDOR_MODULES_LOAD_LAST_LIST[@]}; do
		echo VENDOR_MODULES_LOAD_FIRST_LIST: $module
		sed -n "/${module}:/p" modules.dep.temp
		sed -n "/${module}:/p" modules.dep.temp >> modules.dep.temp2
		sed -i "/${module}:/d" modules.dep.temp
		sed -n "/${module}.*\.ko:/p" modules.dep.temp
		sed -n "/${module}.*\.ko:/p" modules.dep.temp >> modules.dep.temp2
		sed -i "/${module}.*\.ko:/d" modules.dep.temp
	done

	cat modules.dep.temp >> modules.dep.temp1
	cat modules.dep.temp2 >> modules.dep.temp1

	cp modules.dep.temp1 modules.dep
	rm modules.dep.temp
	rm modules.dep.temp1
	rm modules.dep.temp2

	if [[ -n ${ANDROID_PROJECT} ]]; then
		for module in ${RECOVERY_MODULES_LOAD_LIST[@]}; do
			echo RECOVERY_MODULES_LOAD_LIST: $module
			sed -n "/${module}:/p" modules_recovery.dep.temp
			sed -n "/${module}:/p" modules_recovery.dep.temp >> modules_recovery.dep.temp1
			sed -i "/${module}:/d" modules_recovery.dep.temp
			sed -n "/${module}.*\.ko:/p" modules_recovery.dep.temp
			sed -n "/${module}.*\.ko:/p" modules_recovery.dep.temp >> modules_recovery.dep.temp1
			sed -i "/${module}.*\.ko:/d" modules_recovery.dep.temp
		done

		cat modules_recovery.dep.temp >> modules_recovery.dep.temp1

		cp modules_recovery.dep.temp1 modules_recovery.dep
		rm modules_recovery.dep.temp
		rm modules_recovery.dep.temp1
	fi
}

create_ramdisk_vendor_recovery() {
	install_temp=$1
	if [[ -n ${ANDROID_PROJECT} ]]; then
		recovery_install_temp=$2
	fi
	source ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/scripts/amlogic/modules_sequence_list
	ramdisk_module_i=${#RAMDISK_MODULES_LOAD_LIST[@]}
	while [ ${ramdisk_module_i} -gt 0 ]; do
		let ramdisk_module_i--
		echo ramdisk_module_i=$ramdisk_module_i ${RAMDISK_MODULES_LOAD_LIST[${ramdisk_module_i}]}
		if [[ `grep "${RAMDISK_MODULES_LOAD_LIST[${ramdisk_module_i}]}" ${install_temp}` ]]; then
			last_ramdisk_module=${RAMDISK_MODULES_LOAD_LIST[${ramdisk_module_i}]}
			break;
		fi
	done
	# last_ramdisk_module=${RAMDISK_MODULES_LOAD_LIST[${#RAMDISK_MODULES_LOAD_LIST[@]}-1]}
	if [[ -n ${last_ramdisk_module} ]]; then
		last_ramdisk_module_line=`sed -n "/${last_ramdisk_module}/=" ${install_temp}`
		for line in ${last_ramdisk_module_line}; do
			ramdisk_last_line=${line}
		done
	else
		ramdisk_last_line=1
	fi
	export ramdisk_last_line

	if [[ -n ${ANDROID_PROJECT} ]]; then
		recovery_module_i=${#RECOVERY_MODULES_LOAD_LIST[@]}
		#when RECOVERY_MODULES_LOAD_LIST is NULL
		if [ ${#RECOVERY_MODULES_LOAD_LIST[@]}  -eq  0 ]; then
			last_recovery_module=${last_ramdisk_module}
		fi
		while [ ${recovery_module_i} -gt 0 ]; do
			let recovery_module_i--
			echo recovery_module_i=$recovery_module_i ${RECOVERY_MODULES_LOAD_LIST[${recovery_module_i}]}
			if [[ `grep "${RECOVERY_MODULES_LOAD_LIST[${recovery_module_i}]}" ${recovery_install_temp}` ]]; then
				last_recovery_module=${RECOVERY_MODULES_LOAD_LIST[${recovery_module_i}]}
				break;
			fi
		done
		# last_recovery_module=${RECOVERY_MODULES_LOAD_LIST[${#RECOVERY_MODULES_LOAD_LIST[@]}-1]}
		if [[ -n ${last_recovery_module} ]]; then
			last_recovery_module_line=`sed -n "/${last_recovery_module}/=" ${recovery_install_temp}`
			for line in ${last_recovery_module_line}; do
				recovery_last_line=${line}
			done
		else
			recovery_last_line=1
		fi
		sed -n "${ramdisk_last_line},${recovery_last_line}p" ${recovery_install_temp} > recovery_install.sh
		if [[ -n ${last_ramdisk_module} ]]; then
			sed -i "1d" recovery_install.sh
		fi
		mkdir recovery
		cat recovery_install.sh | cut -d ' ' -f 2 > recovery/recovery_modules.order
		if [ ${#RECOVERY_MODULES_LOAD_LIST[@]} -ne 0 ]; then
			cat recovery_install.sh | cut -d ' ' -f 2 | xargs cp -t recovery/
		fi
		sed -i '1s/^/#!\/bin\/sh\n\nset -x\n/' recovery_install.sh
		echo "echo Install recovery modules success!" >> recovery_install.sh
		chmod 755 recovery_install.sh
		mv recovery_install.sh recovery/
	fi

	head -n ${ramdisk_last_line} ${install_temp} > ramdisk_install.sh
	mkdir ramdisk
	cat ramdisk_install.sh | cut -d ' ' -f 2 > ramdisk/ramdisk_modules.order
	cat ramdisk_install.sh | cut -d ' ' -f 2 | xargs mv -t ramdisk/

	sed -i '1s/^/#!\/bin\/sh\n\nset -x\n/' ramdisk_install.sh
	echo "echo Install ramdisk modules success!" >> ramdisk_install.sh
	chmod 755 ramdisk_install.sh
	mv ramdisk_install.sh ramdisk/

	file_last_line=`sed -n "$=" ${install_temp}`
	let line=${file_last_line}-${ramdisk_last_line}
	tail -n ${line} ${install_temp} > vendor_install.sh
	mkdir vendor
	cat vendor_install.sh | cut -d ' ' -f 2 > vendor/vendor_modules.order
	cat vendor_install.sh | cut -d ' ' -f 2 | xargs mv -t vendor/

	sed -i '1s/^/#!\/bin\/sh\n\nset -x\n/' vendor_install.sh
	echo "echo Install vendor modules success!" >> vendor_install.sh
	chmod 755 vendor_install.sh
	mv vendor_install.sh vendor/
}

function modules_install() {
	arg1=$1

	export OUT_AMLOGIC_DIR=${OUT_AMLOGIC_DIR:-$(readlink -m ${COMMON_OUT_DIR}/amlogic)}
	echo $OUT_AMLOGIC_DIR
	rm -rf ${OUT_AMLOGIC_DIR}
	mkdir -p ${OUT_AMLOGIC_DIR}
	mkdir -p ${OUT_AMLOGIC_DIR}/modules
	mkdir -p ${OUT_AMLOGIC_DIR}/ext_modules
	mkdir -p ${OUT_AMLOGIC_DIR}/symbols

	if [[ ${BAZEL} == "1" ]]; then
		local output="out/bazel/output_user_root"
		for dir in `ls ${output}`; do
			if [[ ${dir} =~ ^[0-9A-Fa-f]*$ ]]; then
				digit_output=${output}/${dir}
				break
			fi
		done

		while read module
		do
			module_name=${module##*/}
			if [[ `echo ${module} | grep "^kernel\/"` ]]; then
				if [[ -f ${DIST_DIR}/${module_name} ]]; then
					cp ${DIST_DIR}/${module_name} ${OUT_AMLOGIC_DIR}/modules
				else
					module=`find ${digit_output}/execroot/ -name ${module_name} | grep "amlogic"`
					cp ${module} ${OUT_AMLOGIC_DIR}/modules
				fi
			elif [[ `echo ${module} | grep "^extra\/"` ]]; then
				cp ${DIST_DIR}/${module_name} ${OUT_AMLOGIC_DIR}/ext_modules
			else
				echo "warning unrecognized module: ${module}"
			fi
		done < ${DIST_DIR}/modules.load

		dep_file=`find ${digit_output}/execroot/ -name *.dep | grep "amlogic"`
		cp ${dep_file} ${OUT_AMLOGIC_DIR}/modules/full_modules.dep
		grep -E "^kernel\/" ${dep_file} > ${OUT_AMLOGIC_DIR}/modules/modules.dep
		touch ${module} ${OUT_AMLOGIC_DIR}/ext_modules/ext_modules.order
		for order_file in `find ${digit_output}/execroot/ -name "modules.order.*" | grep "amlogic"`; do
			echo "# ${order_file}" >> ${OUT_AMLOGIC_DIR}/ext_modules/ext_modules.order
			cat ${order_file} >> ${OUT_AMLOGIC_DIR}/ext_modules/ext_modules.order
			echo >> ${OUT_AMLOGIC_DIR}/ext_modules/ext_modules.order
		done
	else
		local MODULES_ROOT_DIR=$(echo ${MODULES_STAGING_DIR}/lib/modules/*)
		pushd ${MODULES_ROOT_DIR}
		local common_drivers=${COMMON_DRIVERS_DIR##*/}
		local modules_list=$(find -type f -name "*.ko")
		for module in ${modules_list}; do
			if [[ -n ${ANDROID_PROJECT} ]]; then			# copy internal build modules
				if [[ `echo ${module} | grep -E "\.\/kernel\/|\/${common_drivers}\/"` ]]; then
					cp ${module} ${OUT_AMLOGIC_DIR}/modules/
				else
					cp ${module} ${OUT_AMLOGIC_DIR}/ext_modules/
				fi
			else							# copy all modules, include external modules
				cp ${module} ${OUT_AMLOGIC_DIR}/modules/
			fi
		done

		if [[ -n ${ANDROID_PROJECT} ]]; then				# internal build modules
			grep -E "^kernel\/|^${common_drivers}\/" modules.dep > ${OUT_AMLOGIC_DIR}/modules/modules.dep
		else								# all modules, include external modules
			cp modules.dep ${OUT_AMLOGIC_DIR}/modules
		fi
		popd
	fi
	pushd ${OUT_AMLOGIC_DIR}/modules
	sed -i 's#[^ ]*/##g' modules.dep

	adjust_sequence_modules_loading "${arg1[*]}"

	touch __install.sh
	touch modules.order
	for loop in `cat modules.dep | sed 's/:.*//'`; do
	        mod_probe $loop
		echo $loop >> modules.order
	        echo insmod $loop >> __install.sh
	done

	cat __install.sh  | awk ' {
		if (!cnt[$2]) {
			print $0;
			cnt[$2]++;
		}
	}' > __install.sh.tmp

	cp modules.order modules.order.back
	cut -d ' ' -f 2 __install.sh.tmp > modules.order

	if [[ -n ${ANDROID_PROJECT} ]]; then
		touch __install_recovery.sh
		touch modules_recovery.order
		for loop in `cat modules_recovery.dep | sed 's/:.*//'`; do
		        mod_probe_recovery $loop
			echo $loop >> modules_recovery.order
		        echo insmod $loop >> __install_recovery.sh
		done

		cat __install_recovery.sh  | awk ' {
			if (!cnt[$2]) {
				print $0;
				cnt[$2]++;
			}
		}' > __install_recovery.sh.tmp

		cut -d ' ' -f 2 __install_recovery.sh.tmp > modules_recovery.order
	fi
	create_ramdisk_vendor_recovery __install.sh.tmp __install_recovery.sh.tmp

	if [[ -n ${MANUAL_INSMOD_MODULE} ]]; then
		install_file=manual_install.sh
	else
		install_file=install.sh
	fi
	echo "#!/bin/sh" > ${install_file}
	echo "cd ramdisk" >> ${install_file}
	echo "./ramdisk_install.sh" >> ${install_file}
	echo "cd ../vendor" >> ${install_file}
	echo "./vendor_install.sh" >> ${install_file}
	echo "cd ../" >> ${install_file}
	chmod 755 ${install_file}

	echo "/modules/: all `wc -l modules.dep | awk '{print $1}'` modules."
	rm __install.sh __install.sh.tmp

	if [[ -n ${ANDROID_PROJECT} ]]; then
		rm __install_recovery.sh __install_recovery.sh.tmp
	fi

	popd

	if [[ ${BAZEL} == "1" ]]; then
		cp ${DIST_DIR}/vmlinux ${OUT_AMLOGIC_DIR}/symbols

		find ${digit_output}/execroot -name *.ko | grep "unstripped" | while read module; do
		        cp ${module} ${OUT_AMLOGIC_DIR}/symbols
			chmod +w ${OUT_AMLOGIC_DIR}/symbols/$(basename ${module})
		done
		chmod -w ${OUT_AMLOGIC_DIR}/symbols/*.ko
	else
		cp ${OUT_DIR}/vmlinux ${OUT_AMLOGIC_DIR}/symbols
		find ${OUT_DIR} -type f -name "*.ko" -exec cp {} ${OUT_AMLOGIC_DIR}/symbols \;
		for ext_module in ${EXT_MODULES}; do
			find ${COMMON_OUT_DIR}/${ext_module} -type f -name "*.ko" -exec cp {} ${OUT_AMLOGIC_DIR}/symbols \;
		done
	fi
}
export -f modules_install

function rename_external_module_name() {
	local external_coppied
	local vendor_coppied
	sed 's/^[\t ]*\|[\t ]*$//g' ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/modules_rename.txt | sed '/^#/d;/^$/d' | sed 's/[[:space:]][[:space:]]*/ /g' | while read module_line; do
		target_module_name=`echo ${module_line%%:*} | sed '/^#/d;/^$/d'`
		modules_name=`echo ${module_line##:*} | sed '/^#/d;/^$/d'`
		[[ -f ${OUT_AMLOGIC_DIR}/ext_modules/${target_module_name} ]] && external_coppied=1
		[[ -f ${OUT_AMLOGIC_DIR}/modules/vendor/${target_module_name} ]] && vendor_coppied=1
		echo target_module_name=$target_module_name modules_name=$modules_name external_coppied=$external_coppied vendor_coppied=$vendor_coppied
		for module in ${modules_name}; do
			echo module=$module
			if [[ -f ${OUT_AMLOGIC_DIR}/ext_modules/${module} ]]; then
				if [[ -z ${external_coppied} ]]; then
					cp ${OUT_AMLOGIC_DIR}/ext_modules/${module} ${OUT_AMLOGIC_DIR}/ext_modules/${target_module_name}
					external_coppied=1
				fi
				rm -f ${OUT_AMLOGIC_DIR}/ext_modules/${module}
			fi
			if [[ -f ${OUT_AMLOGIC_DIR}/modules/vendor/${module} ]]; then
				if [[ -z ${vendor_coppied} ]]; then
					cp ${OUT_AMLOGIC_DIR}/modules/vendor/${module} ${OUT_AMLOGIC_DIR}/modules/vendor/${target_module_name}
					vendor_coppied=1
				fi
				rm -f ${OUT_AMLOGIC_DIR}/modules/vendor/${module}
			fi
		done
		external_coppied=
		vendor_coppied=
	done
}
export -f rename_external_module_name

# function rebuild_rootfs can rebuild the rootfs if rootfs_base.cpio.gz.uboot exist
function rebuild_rootfs() {
	echo
        echo "========================================================"
	if [ -f ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/rootfs_base.cpio.gz.uboot ]; then
		echo "Rebuild rootfs in order to install modules!"
	else
		echo "There's no file ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/rootfs_base.cpio.gz.uboot, so don't rebuild rootfs!"
		return
	fi

	pushd ${OUT_AMLOGIC_DIR}

	local ARCH=arm64
	if [[ -n $1 ]]; then
		ARCH=$1
	fi

	rm rootfs -rf
	mkdir rootfs
	cp ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/rootfs_base.cpio.gz.uboot rootfs
	cd rootfs
	dd if=rootfs_base.cpio.gz.uboot of=rootfs_base.cpio.gz bs=64 skip=1
	gunzip rootfs_base.cpio.gz
	mkdir rootfs
	cd rootfs
	fakeroot cpio -i -F ../rootfs_base.cpio
	if [ -d ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/customer ]; then
		cp ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/customer . -rf
	fi
	cp -rf ../../modules .

	find . | fakeroot cpio -o -H newc | gzip > ../rootfs_new.cpio.gz
	cd ../
	mkimage -A ${ARCH} -O linux -T ramdisk -C none -d rootfs_new.cpio.gz rootfs_new.cpio.gz.uboot
	mv rootfs_new.cpio.gz.uboot ../
	cd ../
	cp rootfs_new.cpio.gz.uboot ${DIST_DIR}

	popd
}
export -f rebuild_rootfs

# function check_undefined_symbol can check the dependence among the modules
# parameter:
#	--modules_depend
function check_undefined_symbol() {
	if [[ ${MODULES_DEPEND} != "1" ]]; then
		return
	fi

	echo "========================================================"
	echo "print modules depend"

	pushd ${OUT_AMLOGIC_DIR}/modules
	echo
	echo "========================================================"
	echo "Functions or variables not defined in this module refer to which module."
	if [[ -n ${LLVM} ]]; then
		compile_tool=${ROOT_DIR}/${CLANG_PREBUILT_BIN}/llvm-
	elif [[ -n ${CROSS_COMPILE} ]]; then
		compile_tool=${CROSS_COMPILE}
	else
		echo "can't find compile tool"
	fi
	${compile_tool}nm ${DIST_DIR}/vmlinux | grep -E " T | D | B | R | W "> vmlinux_T.txt
	# cat __install.sh | grep "insmod" | cut -d ' ' -f 2 > module_list.txt
	cat ramdisk/ramdisk_install.sh | grep "insmod" | cut -d ' ' -f 2 > module_list.txt
	cat vendor/vendor_install.sh | grep "insmod" | cut -d ' ' -f 2 >> module_list.txt
	cp ramdisk/*.ko .
	cp vendor/*.ko .
	while read LINE
	do
		echo ${LINE}
		for U in `${compile_tool}nm ${LINE} | grep " U " | sed -e 's/^\s*//' -e 's/\s*$//' | cut -d ' ' -f 2`
		do
			#echo ${U}
			U_v=`grep -w ${U} vmlinux_T.txt`
			in_vmlinux=0
			if [ -n "${U_v}" ];
			then
				#printf "\t%-50s <== vmlinux\n" ${U}
				in_vmlinux=1
				continue
			fi
			in_module=0
			MODULE=
			while read LINE1
			do
				U_m=`${compile_tool}nm ${LINE1} | grep -E " T | D | B | R " | grep -v "\.cfi_jt" | grep "${U}"`
				if [ -n "${U_m}" ];
				then
					in_module=1
					MODULE=${LINE1}
				fi
			done < module_list.txt
			if [ ${in_module} -eq "1" ];
			then
				printf "\t%-50s <== %s\n" ${U} ${MODULE}
				continue
			else
				printf "\t%-50s <== none\n" ${U}
			fi
		done
		echo
		echo
	done  < module_list.txt
	rm vmlinux_T.txt
	rm module_list.txt
	rm *.ko
	popd
}
export -f check_undefined_symbol

function reorganized_abi_symbol_list_file() { # delete the extra information but symbol
	cat $@ | sed '/^$/d' >> ${symbol_tmp} # remove blank lines
	sed -i '/^\[/d' ${symbol_tmp} # remove the title
	sed -i '/^\#/d' ${symbol_tmp} # remove the comment
}
export -f reorganized_abi_symbol_list_file

function abi_symbol_list_detect () { # detect symbol information that should be submitted or fix
	symbol_file1=${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/android/abi_gki_aarch64_amlogic
	symbol_file2=${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/android/abi_gki_aarch64_amlogic.10
	symbol_file3=${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/android/abi_gki_aarch64_amlogic.debug
	symbol_file4=${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/android/abi_gki_aarch64_amlogic.illegal

	file_list=("${symbol_file1} ${symbol_file2} ${symbol_file3} ${symbol_file4}")
	for file in ${file_list}
	do
		local symbol_tmp=`mktemp tmp.XXXXXXXXXXXX`
		reorganized_abi_symbol_list_file "${file}"

		if [[ -s ${symbol_tmp} ]]; then
			if [[ ${file} =~ abi_gki_aarch64_amlogic.illegal ]]; then
				echo "WARNING: The symbols in ${file} are illegal, please deal with them as soon as possible!!!"
			else
				echo "WARNING: The symbols in ${file} should be submit to google!!!"
			fi
			cat ${symbol_tmp}
			echo -e "\n------------------------------------------------------------"
		fi
		rm ${symbol_tmp}
	done
}
export -f abi_symbol_list_detect

# adjust_config_action concerns three types of cmd:
# parameters:
#	--menuconfig:      make menuconfig manually based on different gki standard
#	--basicconfig:     only config kernel with google original gki_defconfig as base
#	--check_defconfig: contrast the defconfig generated in out directory with gki_defconfig and show the difference
function adjust_config_action () {
	if [[ -n ${MENUCONFIG} ]] || [[ -n ${BASICCONFIG} ]] || [[ ${CHECK_DEFCONFIG} -eq "1" ]]; then
		# ${ROOT_DIR}/${BUILD_DIR}/config.sh menuconfig
		HERMETIC_TOOLCHAIN=0
		source "${ROOT_DIR}/${BUILD_DIR}/build_utils.sh"
		source "${ROOT_DIR}/${BUILD_DIR}/_setup_env.sh"

		orig_config=$(mktemp)
		orig_defconfig=$(mktemp)
		out_config="${OUT_DIR}/.config"
		out_defconfig="${OUT_DIR}/defconfig"
		changed_config=$(mktemp)
		changed_defconfig=$(mktemp)

		if [[ -n ${BASICCONFIG} ]]; then # config kernel with gki_defconfig or make menuconfig based on it
			set -x
			defconfig_name=`basename ${GKI_BASE_CONFIG}`
			(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" ${defconfig_name})
			(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" savedefconfig)
			cp ${out_config} ${orig_config}
			cp ${out_defconfig} ${orig_defconfig}
			if [ "${BASICCONFIG}" = "m" ]; then # make menuconfig based on gki_defconfig
				(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" menuconfig)
			fi
			(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" savedefconfig)
			${KERNEL_DIR}/scripts/diffconfig ${orig_config} ${out_config} > ${changed_config}
			${KERNEL_DIR}/scripts/diffconfig ${orig_defconfig} ${out_defconfig} > ${changed_defconfig}
			if [ "${ARCH}" = "arm" ]; then
				cp ${out_defconfig} ${GKI_BASE_CONFIG}
			fi
			set +x # show the difference between the gki_defconfig and the config after make menuconfig
			echo
			echo "========================================================"
			echo "==================== .config diff   ===================="
			cat ${changed_config}
			echo "==================== defconfig diff ===================="
			cat ${changed_defconfig}
			echo "========================================================"
			echo
		elif [[ ${CHECK_DEFCONFIG} -eq "1" ]]; then # compare the defconfig generated in out directory with gki_defconfig
			set -x
			pre_defconfig_cmds
			(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" ${DEFCONFIG})
			(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" savedefconfig) # export the defconfig to out directory
			diff -u ${ROOT_DIR}/${GKI_BASE_CONFIG} ${OUT_DIR}/defconfig
			post_defconfig_cmds
			set +x
		else # make menuconfig based on config with different gki standard
			set -x
			pre_defconfig_cmds
			(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" ${DEFCONFIG})
			(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" savedefconfig)
			cp ${out_config} ${orig_config}
			cp ${out_defconfig} ${orig_defconfig}
			(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" menuconfig)
			(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" savedefconfig)
			${KERNEL_DIR}/scripts/diffconfig ${orig_config} ${out_config} > ${changed_config}
			${KERNEL_DIR}/scripts/diffconfig ${orig_defconfig} ${out_defconfig} > ${changed_defconfig}
			post_defconfig_cmds
			set +x
			echo
			echo "========================================================"
			echo "if the config follows GKI2.0, please add it to the file amlogic_gki.fragment manually"
			echo "if the config follows GKI1.0 optimize, please add it to the file amlogic_gki.10 manually"
			echo "if the config follows GKI1.0 debug, please add it to the file amlogic_gki.debug manually"
			echo "==================== .config diff   ===================="
			cat ${changed_config}
			echo "==================== defconfig diff ===================="
			cat ${changed_defconfig}
			echo "========================================================"
			echo
		fi
		rm -f ${orig_config} ${changed_config} ${orig_defconfig} ${changed_defconfig}
		exit
	fi
}
export -f adjust_config_action

# function build_part_of_kernel can only build part of kernel such as image modules or dtbs
# parameter:
#	--image:   only build image
#	--modules: only build kernel modules
#	--dtbs:    only build dtbs
function build_part_of_kernel () {
	if [[ -n ${IMAGE} ]] || [[ -n ${MODULES} ]] || [[ -n ${DTB_BUILD} ]]; then
		old_path=${PATH}
		source "${ROOT_DIR}/${BUILD_DIR}/build_utils.sh"
		source "${ROOT_DIR}/${BUILD_DIR}/_setup_env.sh"

		if [[ ! -f ${OUT_DIR}/.config ]]; then
			pre_defconfig_cmds
			set -x
			(cd ${KERNEL_DIR} && make ${TOOL_ARGS} O=${OUT_DIR} "${MAKE_ARGS[@]}" ${DEFCONFIG})
			set +x
			post_defconfig_cmds
		fi

		if [[ -n ${IMAGE} ]]; then
			set -x
			if [ "${ARCH}" = "arm64" ]; then
				(cd ${OUT_DIR} && make O=${OUT_DIR} ${TOOL_ARGS} "${MAKE_ARGS[@]}" -j$(nproc) Image)
			elif [ "${ARCH}" = "arm" ]; then
				(cd ${OUT_DIR} && make O=${OUT_DIR} ${TOOL_ARGS} "${MAKE_ARGS[@]}" -j$(nproc) LOADADDR=0x108000 uImage)
			fi
			set +x
		fi
		mkdir -p ${DIST_DIR}
		if [[ -n ${DTB_BUILD} ]]; then
			set -x
			(cd ${OUT_DIR} && make O=${OUT_DIR} ${TOOL_ARGS} "${MAKE_ARGS[@]}" -j$(nproc) dtbs)
			set +x
		fi
		if [[ -n ${MODULES} ]]; then
			export MODULES_STAGING_DIR=$(readlink -m ${COMMON_OUT_DIR}/staging)
			rm -rf ${MODULES_STAGING_DIR}
			mkdir -p ${MODULES_STAGING_DIR}
			if [ "${DO_NOT_STRIP_MODULES}" != "1" ]; then
				MODULE_STRIP_FLAG="INSTALL_MOD_STRIP=1"
			fi
			if [[ `grep "CONFIG_AMLOGIC_IN_KERNEL_MODULES=y" ${ROOT_DIR}/${FRAGMENT_CONFIG}` ]]; then
				set -x
				(cd ${OUT_DIR} && make O=${OUT_DIR} ${TOOL_ARGS} "${MAKE_ARGS[@]}" -j$(nproc) modules)
				(cd ${OUT_DIR} && make O=${OUT_DIR} ${TOOL_ARGS} ${MODULE_STRIP_FLAG} INSTALL_MOD_PATH=${MODULES_STAGING_DIR} "${MAKE_ARGS[@]}" modules_install)
				set +x
			fi
			echo EXT_MODULES=$EXT_MODULES
			prepare_module_build
			if [[ -z "${SKIP_EXT_MODULES}" ]] && [[ -n "${EXT_MODULES}" ]]; then
				echo "========================================================"
				echo " Building external modules and installing them into staging directory"
				KERNEL_UAPI_HEADERS_DIR=$(readlink -m ${COMMON_OUT_DIR}/kernel_uapi_headers)
				for EXT_MOD in ${EXT_MODULES}; do
					EXT_MOD_REL=$(rel_path ${ROOT_DIR}/${EXT_MOD} ${KERNEL_DIR})
					mkdir -p ${OUT_DIR}/${EXT_MOD_REL}
					set -x
					make -C ${EXT_MOD} M=${EXT_MOD_REL} KERNEL_SRC=${ROOT_DIR}/${KERNEL_DIR}  \
						O=${OUT_DIR} ${TOOL_ARGS} "${MAKE_ARGS[@]}"
					make -C ${EXT_MOD} M=${EXT_MOD_REL} KERNEL_SRC=${ROOT_DIR}/${KERNEL_DIR}  \
						O=${OUT_DIR} ${TOOL_ARGS} ${MODULE_STRIP_FLAG}         \
						INSTALL_MOD_PATH=${MODULES_STAGING_DIR}                \
						INSTALL_MOD_DIR="extra/${EXT_MOD}"                     \
						INSTALL_HDR_PATH="${KERNEL_UAPI_HEADERS_DIR}/usr"      \
						"${MAKE_ARGS[@]}" modules_install
					set +x
				done
			fi
			export OUT_AMLOGIC_DIR=$(readlink -m ${COMMON_OUT_DIR}/amlogic)
			set -x
			extra_cmds
			set +x
			MODULES=$(find ${MODULES_STAGING_DIR} -type f -name "*.ko")
			cp -p ${MODULES} ${DIST_DIR}

			new_path=${PATH}
			PATH=${old_path}
			echo "========================================================"
			if [ -f ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/rootfs_base.cpio.gz.uboot ]; then
				echo "Rebuild rootfs in order to install modules!"
				rebuild_rootfs ${ARCH}
			else
				echo "There's no file ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/rootfs_base.cpio.gz.uboot, so don't rebuild rootfs!"
			fi
			PATH=${new_path}
		fi
		if [ -n "${DTS_EXT_DIR}" ]; then
			if [ -d "${ROOT_DIR}/${DTS_EXT_DIR}" ]; then
				DTS_EXT_DIR=$(rel_path ${ROOT_DIR}/${DTS_EXT_DIR} ${KERNEL_DIR})
				if [ -d ${OUT_DIR}/${DTS_EXT_DIR} ]; then
					FILES="$FILES `ls ${OUT_DIR}/${DTS_EXT_DIR}`"
				fi
			fi
		fi
		for FILE in ${FILES}; do
			if [ -f ${OUT_DIR}/${FILE} ]; then
				echo "  $FILE"
				cp -p ${OUT_DIR}/${FILE} ${DIST_DIR}/
			elif [[ "${FILE}" =~ \.dtb|\.dtbo ]]  && \
				[ -n "${DTS_EXT_DIR}" ] && [ -f "${OUT_DIR}/${DTS_EXT_DIR}/${FILE}" ] ; then
				# DTS_EXT_DIR is recalculated before to be relative to KERNEL_DIR
				echo "  $FILE"
				cp -p "${OUT_DIR}/${DTS_EXT_DIR}/${FILE}" "${DIST_DIR}/"
			else
				echo "  $FILE is not a file, skipping"
			fi
		done
		exit
	fi
}
export -f build_part_of_kernel

function export_env_variable () {
	export ABI BUILD_CONFIG LTO KMI_SYMBOL_LIST_STRICT_MODE CHECK_DEFCONFIG MANUAL_INSMOD_MODULE ARCH
	export KERNEL_DIR COMMON_DRIVERS_DIR BUILD_DIR ANDROID_PROJECT GKI_CONFIG UPGRADE_PROJECT ANDROID_VERSION FAST_BUILD CHECK_GKI_20 DEV_CONFIGS
	export FULL_KERNEL_VERSION BAZEL

	echo ROOT_DIR=$ROOT_DIR
	echo ABI=${ABI} BUILD_CONFIG=${BUILD_CONFIG} LTO=${LTO} KMI_SYMBOL_LIST_STRICT_MODE=${KMI_SYMBOL_LIST_STRICT_MODE} CHECK_DEFCONFIG=${CHECK_DEFCONFIG} MANUAL_INSMOD_MODULE=${MANUAL_INSMOD_MODULE}
	echo KERNEL_DIR=${KERNEL_DIR} COMMON_DRIVERS_DIR=${COMMON_DRIVERS_DIR} BUILD_DIR=${BUILD_DIR} ANDROID_PROJECT=${ANDROID_PROJECT} GKI_CONFIG=${GKI_CONFIG} UPGRADE_PROJECT=${UPGRADE_PROJECT} ANDROID_VERSION=${ANDROID_VERSION}  FAST_BUILD=${FAST_BUILD} CHECK_GKI_20=${CHECK_GKI_20}
	echo FULL_KERNEL_VERSION=${FULL_KERNEL_VERSION} BAZEL=${BAZEL}
	echo MENUCONFIG=${MENUCONFIG} BASICCONFIG=${BASICCONFIG} IMAGE=${IMAGE} MODULES=${MODULES} DTB_BUILD=${DTB_BUILD}
}
export -f export_env_variable

function handle_input_parameters () {
	VA=
	ARGS=()
	for i in "$@"
	do
		case $i in
		--arch)
			ARCH=$2
			VA=1
			shift
			;;
		--abi)
			ABI=1
			shift
			;;
		--build_config)
			BUILD_CONFIG=$2
			VA=1
			shift
			;;
		--lto)
			LTO=$2
			VA=1
			shift
			;;
		--symbol_strict)
			KMI_SYMBOL_LIST_STRICT_MODE=$2
			VA=1
			shift
			;;
		--menuconfig)
			MENUCONFIG=1
			shift
			;;
		--basicconfig)
			if [ "$2" = "m" ] || [ "$2" = "n" ]; then
				BASICCONFIG=$2
			else
				BASICCONFIG="m"
			fi
			VA=1
			shift
			;;
		--image)
			IMAGE=1
			shift
			;;
		--modules)
			MODULES=1
			shift
			break
			;;
		--dtbs)
			DTB_BUILD=1
			shift
			;;
		--build_dir)
			BUILD_DIR=$2
			VA=1
			shift
			;;
		--check_defconfig)
			CHECK_DEFCONFIG=1
			shift
			;;
		--modules_depend)
			MODULES_DEPEND=1
			shift
			;;
		--android_project)
			ANDROID_PROJECT=$2
			VA=1
			shift
			;;
		--gki_20)
			GKI_CONFIG=gki_20
			shift
			;;
		--gki_10)
			GKI_CONFIG=gki_10
			shift
			;;
		--gki_debug)
			GKI_CONFIG=gki_debug
			shift
			;;
		--fast_build)
			FAST_BUILD=1
			shift
			;;
		--upgrade)
			UPGRADE_PROJECT=1
			ANDROID_VERSION=$2
			VA=1
			shift
			;;
		--manual_insmod_module)
			MANUAL_INSMOD_MODULE=1
			shift
			;;
		--check_gki_20)
			CHECK_GKI_20=1
			GKI_CONFIG=gki_20
			LTO=none
			shift
			;;
		--dev_config)
			DEV_CONFIGS=$2
			VA=1
			shift
			;;
		--bazel)
			BAZEL=1
			shift
			;;
		-h|--help)
			show_help
			exit 0
			;;
		*)
			if [[ -n $1 ]];
			then
				if [[ -z ${VA} ]];
				then
					ARGS+=("$1")
				fi
			fi
			VA=
			shift
			;;
		esac
	done
}
export -f handle_input_parameters

function set_default_parameters () {
	if [ "${ARCH}" = "arm" ]; then
		ARGS+=("LOADADDR=0x108000")
	else
		ARCH=arm64
	fi

	if [[ -z "${ABI}" ]]; then
		ABI=0
	fi
	if [[ -z "${LTO}" ]]; then
		LTO=thin
	fi
	if [[ -n ${CHECK_GKI_20} && -z ${ANDROID_PROJECT} ]]; then
		ANDROID_PROJECT=ohm
	fi

	if [[ -z "${BUILD_CONFIG}" ]]; then
		if [ "${ARCH}" = "arm64" ]; then
				BUILD_CONFIG=${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/build.config.amlogic
		elif [ "${ARCH}" = "arm" ]; then
				BUILD_CONFIG=${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/build.config.amlogic32
		fi
	fi
	if [[ -z "${BUILD_DIR}" ]]; then
		BUILD_DIR=build
	fi

	version_message=$(grep -rn BRANCH= ${KERNEL_DIR}/build.config.constants)
	version_message="common${version_message##*android}"
	if [[ -n ${FULL_KERNEL_VERSION} ]]; then
		if [[ "${FULL_KERNEL_VERSION}" != "${version_message}" ]]; then
			echo "kernel version is not match!!"
			exit
		fi
	else
		FULL_KERNEL_VERSION=${version_message}
	fi

	if [[ -z ${BAZEL} ]]; then
		[[ "${FULL_KERNEL_VERSION}" != "common13-5.15" && "${ARCH}" == "arm64" && -z ${UPGRADE_PROJECT} ]] && BAZEL=1
	fi

	auto_patch_to_common_dir

	if [[ ! -f ${BUILD_DIR}/build_abi.sh && ${BAZEL} == 0 ]]; then
		echo "The directory of build does not exist";
		exit
	fi

	ROOT_DIR=$(readlink -f $(dirname $0))
	if [[ ! -f ${ROOT_DIR}/${KERNEL_DIR}/init/main.c ]]; then
		ROOT_DIR=`pwd`
		if [[ ! -f ${ROOT_DIR}/${KERNEL_DIR}/init/main.c ]]; then
			echo "the file path of $0 is incorrect"
			exit
		fi
	fi
	export ROOT_DIR

	CHECK_DEFCONFIG=${CHECK_DEFCONFIG:-0}
	MODULES_DEPEND=${MODULES_DEPEND:-0}
	if [[ ! -f ${KERNEL_BUILD_VAR_FILE} ]]; then
		export KERNEL_BUILD_VAR_FILE=`mktemp /tmp/kernel.XXXXXXXXXXXX`
		RM_KERNEL_BUILD_VAR_FILE=1
	fi

	GKI_CONFIG=${GKI_CONFIG:-gki_debug}

	export CROSS_COMPILE=

	if [ "${ABI}" -eq "1" ]; then
		export OUT_DIR_SUFFIX="_abi"
	else
		OUT_DIR_SUFFIX=
	fi
}
export -f set_default_parameters

function auto_patch_to_common_dir () {
	#first auto patch when param parse end

	if [[ -f ${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/auto_patch/auto_patch.sh ]]; then
        	export PATCH_PARM
		${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/auto_patch/auto_patch.sh ${FULL_KERNEL_VERSION}
	fi

	if [[ ${ONLY_PATCH} -eq "1" ]]; then
		cd ${CURRENT_DIR}
		exit
	fi
}
export -f auto_patch_to_common_dir

function handle_input_parameters_for_smarthome () {
	VA=
	ARGS=()
	for i in "$@"
	do
		case $i in
		--savedefconfig)
			SAVEDEFCONFIG=1
			shift
			;;
		--menuconfig)
			MENUCONFIG=1
			shift
			;;
		--dtb)
			DTB=1
			shift
			;;
		--manual_insmod_module)
			MANUAL_INSMOD_MODULE=1
			shift
			;;
		--patch)
			ONLY_PATCH=1
			shift
			;;
		-h|--help)
			show_help
			exit 0
			;;
		*)
			if [[ -n $1 ]];
			then
				if [[ -z ${VA} ]];
				then
					ARGS+=("$1")
				fi
			fi
			VA=
			shift
			;;
		esac
	done
}

export -f handle_input_parameters_for_smarthome

function set_default_parameters_for_smarthome () {
	version_message=$(grep -rn BRANCH= ${KERNEL_DIR}/build.config.constants)
	version_message="common${version_message##*android}"
	if [[ -n ${FULL_KERNEL_VERSION} ]]; then
		if [[ "${FULL_KERNEL_VERSION}" != "${version_message}" ]]; then
			echo "kernel version is not match!!"
			exit
		fi
	else
		FULL_KERNEL_VERSION=${version_message}
	fi

	tool_args=()
	prebuilts_paths=(
		CLANG_PREBUILT_BIN
		#BUILDTOOLS_PREBUILT_BIN
	)
	echo CC_CLANG=$CC_CLANG
	if [[ $CC_CLANG -eq "1" ]]; then
		source ${ROOT_DIR}/${KERNEL_DIR}/build.config.common
		if [[ -n "${LLVM}" ]]; then
			tool_args+=("LLVM=1")
		fi
		#if [ -n "${DTC}" ]; then
		#	tool_args+=("DTC=${DTC}")
		#fi
		for prebuilt_bin in "${prebuilts_paths[@]}"; do
			prebuilt_bin=\${${prebuilt_bin}}
			eval prebuilt_bin="${prebuilt_bin}"
			if [ -n "${prebuilt_bin}" ]; then
				PATH=${PATH//"${ROOT_DIR}\/${prebuilt_bin}:"}
				PATH=${ROOT_DIR}/${prebuilt_bin}:${PATH} # add the clang tool to env PATH
			fi
		done
		export PATH
	elif [[ -n $CROSS_COMPILE_TOOL ]]; then
		export CROSS_COMPILE=${CROSS_COMPILE_TOOL}
	fi

	if [[ $ARCH == arm64 ]]; then
		OUTDIR=${ROOT_DIR}/out/kernel-5.15-64
	elif [[ $ARCH == arm ]]; then
		OUTDIR=${ROOT_DIR}/out/kernel-5.15-32
		tool_args+=("LOADADDR=0x108000")
	elif [[ $ARCH == riscv ]]; then
		OUTDIR=${ROOT_DIR}/out/riscv-kernel-5.15-64
	fi
	TOOL_ARGS="${tool_args[@]}"

	OUT_DIR=${OUTDIR}/common
	mkdir -p ${OUT_DIR}
	if [ "${SKIP_RM_OUTDIR}" != "1" ] ; then
		rm -rf ${OUTDIR}
	fi

	echo "========================================================"
	echo ""
	export DIST_DIR=$(readlink -m ${OUTDIR}/dist)
	export MODULES_STAGING_DIR=$(readlink -m ${OUTDIR}/staging)
	export OUT_AMLOGIC_DIR=$(readlink -m ${OUTDIR}/amlogic)
	echo OUTDIR=$OUTDIR DIST_DIR=$DIST_DIR MODULES_STAGING_DIR=$MODULES_STAGING_DIR KERNEL_DIR=$KERNEL_DIR


	source ${ROOT_DIR}/build/kernel/build_utils.sh

	DTS_EXT_DIR=${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/arch/${ARCH}/boot/dts/amlogic
	DTS_EXT_DIR=$(rel_path ${ROOT_DIR}/${DTS_EXT_DIR} ${KERNEL_DIR})
	export dtstree=${DTS_EXT_DIR}
	export DTC_INCLUDE=${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/include

	EXT_MODULES="
		${EXT_MODULES}
	"

	EXT_MODULES_CONFIG="
		${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/scripts/amlogic/ext_modules_config
	"

	EXT_MODULES_PATH="
		${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/scripts/amlogic/ext_modules_path
	"

	POST_KERNEL_BUILD_CMDS="prepare_module_build"
	EXTRA_CMDS="extra_cmds"

	IN_KERNEL_MODULES=1
}

export -f set_default_parameters_for_smarthome

function savedefconfig_cmd_for_smarthome () {
	if [[ -n ${SAVEDEFCONFIG} ]]; then
		set -x
		make ARCH=${ARCH} -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${DEFCONFIG}
		make ARCH=${ARCH} -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} savedefconfig
		rm ${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/arch/${ARCH}/configs/${DEFCONFIG}
		cp -f ${OUT_DIR}/defconfig  ${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/arch/${ARCH}/configs/${DEFCONFIG}
		set +x
		exit
	fi
}
export -f savedefconfig_cmd_for_smarthome

function only_build_dtb_for_smarthome () {
	if [[ -n ${DTB} ]]; then
		set -x
		make ARCH=${ARCH} -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} ${DEFCONFIG}
		make ARCH=${ARCH} -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} dtbs || exit
		set +x
		exit
	fi
}
export -f only_build_dtb_for_smarthome

function make_menuconfig_cmd_for_smarthome () {
	if [[ -n ${MENUCONFIG} ]]; then
		set -x
		make ARCH=${ARCH} -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${DEFCONFIG}
		make ARCH=${ARCH} -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} menuconfig
		set +x
		exit
	fi
}
export -f make_menuconfig_cmd_for_smarthome

function build_kernel_for_different_cpu_architecture () {
	set -x
	if [[ $ARCH == arm64 ]]; then
		make ARCH=arm64 -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} ${DEFCONFIG}
		make ARCH=arm64 -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} headers_install &&
		make ARCH=arm64 -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} Image -j12 &&
		make ARCH=arm64 -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} modules -j12 &&
		make ARCH=arm64 -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} INSTALL_MOD_PATH=${MODULES_STAGING_DIR} INSTALL_MOD_STRIP=1 modules_install -j12 &&
		make ARCH=arm64 -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} dtbs -j12 || exit
	elif [[ $ARCH == arm ]]; then
		make ARCH=arm -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} ${DEFCONFIG}
		make ARCH=arm -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} headers_install &&
		make ARCH=arm -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} uImage -j12 &&
		make ARCH=arm -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} modules -j12 &&
		make ARCH=arm -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} INSTALL_MOD_PATH=${MODULES_STAGING_DIR} INSTALL_MOD_STRIP=1 modules_install -j12 &&
		make ARCH=arm -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} dtbs -j12 || exit
	elif [[ $ARCH == riscv ]]; then
		make ARCH=riscv -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} ${DEFCONFIG}
		make ARCH=riscv -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} headers_install &&
		make ARCH=riscv -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} Image -j12 &&
		make ARCH=riscv -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} modules -j12 &&
		make ARCH=riscv -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} INSTALL_MOD_PATH=${MODULES_STAGING_DIR} modules_install -j12 &&
		make ARCH=riscv -C ${ROOT_DIR}/${KERNEL_DIR} O=${OUT_DIR} ${TOOL_ARGS} dtbs -j12 || exit
	fi
	cp ${OUT_DIR}/arch/${ARCH}/boot/Image* ${DIST_DIR}
	cp ${OUT_DIR}/arch/${ARCH}/boot/uImage* ${DIST_DIR}
	cp ${OUT_DIR}/${COMMON_DRIVERS_DIR}/arch/${ARCH}/boot/dts/amlogic/*.dtb ${DIST_DIR}
	cp ${OUT_DIR}/vmlinux ${DIST_DIR}
	set +x
}
export -f build_kernel_for_different_cpu_architecture

function build_ext_modules() {
	for EXT_MOD in ${EXT_MODULES}; do
		EXT_MOD_REL=$(rel_path ${ROOT_DIR}/${EXT_MOD} ${KERNEL_DIR})
		mkdir -p ${OUT_DIR}/${EXT_MOD_REL}

		set -x
		make ARCH=${ARCH} -C ${ROOT_DIR}/${EXT_MOD} M=${EXT_MOD_REL} KERNEL_SRC=${ROOT_DIR}/${KERNEL_DIR}  \
				O=${OUT_DIR} ${TOOL_ARGS} -j12 || exit
		make ARCH=${ARCH} -C ${ROOT_DIR}/${EXT_MOD} M=${EXT_MOD_REL} KERNEL_SRC=${ROOT_DIR}/${KERNEL_DIR}  \
				O=${OUT_DIR} ${TOOL_ARGS} ${MODULE_STRIP_FLAG}		\
				INSTALL_MOD_PATH=${MODULES_STAGING_DIR}			\
				INSTALL_MOD_DIR="extra/${EXT_MOD}"			\
				INSTALL_MOD_STRIP=1					\
				modules_install -j12 || exit
		set +x
	done
}
export -f build_ext_modules

function copy_modules_and_rebuild_rootfs_for_smarthome () {

	copy_modules_files_to_dist_dir

	if [ -f ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/rootfs_base.cpio.gz.uboot ]; then
		echo "========================================================"
		echo "Rebuild rootfs in order to install modules!"
		rebuild_rootfs ${ARCH}
		echo "Build success!"
	else
		echo "There's no file ${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/rootfs_base.cpio.gz.uboot, so don't rebuild rootfs!"
	fi
}
export -f copy_modules_and_rebuild_rootfs_for_smarthome

function copy_modules_files_to_dist_dir () {
	MODULES=$(find ${MODULES_STAGING_DIR} -type f -name "*.ko")
	if [ -n "${MODULES}" ]; then
		if [ -n "${IN_KERNEL_MODULES}" -o -n "${EXT_MODULES}" -o -n "${EXT_MODULES_MAKEFILE}" ]; then
			echo "========================================================"
			echo " Copying modules files"
			for module in ${MODULES}; do
				cp ${module} ${DIST_DIR}
			done
			if [ "${COMPRESS_MODULES}" = "1" ]; then
				echo " Archiving modules to ${MODULES_ARCHIVE}"
				tar --transform="s,.*/,," -czf ${DIST_DIR}/${MODULES_ARCHIVE} ${MODULES[@]}
			fi
		fi
	fi
}
export -f copy_modules_files_to_dist_dir

function copy_files_to_dist_dir () {
	echo "========================================================"
	echo " Copying files"
	for FILE in ${FILES}; do
		if [ -f ${OUT_DIR}/${FILE} ]; then
			echo "  $FILE"
			cp -p ${OUT_DIR}/${FILE} ${DIST_DIR}/
		elif [[ "${FILE}" =~ \.dtb|\.dtbo ]]  && \
		[ -n "${DTS_EXT_DIR}" ] && [ -f "${OUT_DIR}/${DTS_EXT_DIR}/${FILE}" ] ; then
			# DTS_EXT_DIR is recalculated before to be relative to KERNEL_DIR
			echo "  $FILE"
			cp -p "${OUT_DIR}/${DTS_EXT_DIR}/${FILE}" "${DIST_DIR}/"
		else
			echo "  $FILE is not a file, skipping"
		fi
	done
}
export -f copy_files_to_dist_dir

function make_dtbo() {
	if [[ -n "${BUILD_DTBO_IMG}" ]]; then
		echo "========================================================"
		echo " Creating dtbo image at ${DIST_DIR}/dtbo.img"
		(
			cd ${OUT_DIR}
			mkdtimg create "${DIST_DIR}"/dtbo.img ${MKDTIMG_FLAGS} ${MKDTIMG_DTBOS}
		)
	fi
}
export -f make_dtbo

function installing_UAPI_kernel_headers () {
	if [ -z "${SKIP_CP_KERNEL_HDR}" ]; then
		echo "========================================================"
		echo " Installing UAPI kernel headers:"
		mkdir -p "${KERNEL_UAPI_HEADERS_DIR}/usr"
		make -C ${OUT_DIR} O=${OUT_DIR} ${TOOL_ARGS}                                \
				INSTALL_HDR_PATH="${KERNEL_UAPI_HEADERS_DIR}/usr" "${MAKE_ARGS[@]}" \
				headers_install
		# The kernel makefiles create files named ..install.cmd and .install which
		# are only side products. We don't want those. Let's delete them.
		find ${KERNEL_UAPI_HEADERS_DIR} \( -name ..install.cmd -o -name .install \) -exec rm '{}' +
		KERNEL_UAPI_HEADERS_TAR=${DIST_DIR}/kernel-uapi-headers.tar.gz
		echo " Copying kernel UAPI headers to ${KERNEL_UAPI_HEADERS_TAR}"
		tar -czf ${KERNEL_UAPI_HEADERS_TAR} --directory=${KERNEL_UAPI_HEADERS_DIR} usr/
	fi
}
export -f installing_UAPI_kernel_headers

function copy_kernel_headers_to_compress () {
	if [ -z "${SKIP_CP_KERNEL_HDR}" ] ; then
		echo "========================================================"
		KERNEL_HEADERS_TAR=${DIST_DIR}/kernel-headers.tar.gz
		echo " Copying kernel headers to ${KERNEL_HEADERS_TAR}"
		pushd $ROOT_DIR/$KERNEL_DIR
			find arch include $OUT_DIR -name *.h -print0               \
				| tar -czf $KERNEL_HEADERS_TAR                     \
				--absolute-names                                 \
				--dereference                                    \
				--transform "s,.*$OUT_DIR,,"                     \
				--transform "s,^,kernel-headers/,"               \
				--null -T -
		popd
	fi
}
export -f copy_kernel_headers_to_compress

function set_default_parameters_for_32bit () {
	tool_args=()
	prebuilts_paths=(
		CLANG_PREBUILT_BIN
		CLANGTOOLS_PREBUILT_BIN
		RUST_PREBUILT_BIN
		LZ4_PREBUILTS_BIN
		DTC_PREBUILTS_BIN
		LIBUFDT_PREBUILTS_BIN
		BUILDTOOLS_PREBUILT_BIN
	)
	echo CC_CLANG=$CC_CLANG
	if [[ $CC_CLANG -eq "1" ]]; then
		source ${ROOT_DIR}/${KERNEL_DIR}/build.config.common
		if [[ -n "${LLVM}" ]]; then
			tool_args+=("LLVM=1")
			# Reset a bunch of variables that the kernel's top level Makefile does, just
			# in case someone tries to use these binaries in this script such as in
			# initramfs generation below.
			HOSTCC=clang
			HOSTCXX=clang++
			CC=clang
			LD=ld.lld
			AR=llvm-ar
			NM=llvm-nm
			OBJCOPY=llvm-objcopy
			OBJDUMP=llvm-objdump
			OBJSIZE=llvm-size
			READELF=llvm-readelf
			STRIP=llvm-strip
		else
			if [ -n "${HOSTCC}" ]; then
				tool_args+=("HOSTCC=${HOSTCC}")
			fi

			if [ -n "${CC}" ]; then
				tool_args+=("CC=${CC}")
				if [ -z "${HOSTCC}" ]; then
				tool_args+=("HOSTCC=${CC}")
				fi
			fi

			if [ -n "${LD}" ]; then
				tool_args+=("LD=${LD}" "HOSTLD=${LD}")
			fi

			if [ -n "${NM}" ]; then
				tool_args+=("NM=${NM}")
			fi

			if [ -n "${OBJCOPY}" ]; then
				tool_args+=("OBJCOPY=${OBJCOPY}")
			fi
		fi

		if [ -n "${DTC}" ]; then
			tool_args+=("DTC=${DTC}")
		fi
		for prebuilt_bin in "${prebuilts_paths[@]}"; do
			prebuilt_bin=\${${prebuilt_bin}}
			eval prebuilt_bin="${prebuilt_bin}"
			if [ -n "${prebuilt_bin}" ]; then
				PATH=${PATH//"${ROOT_DIR}\/${prebuilt_bin}:"}
				PATH=${ROOT_DIR}/${prebuilt_bin}:${PATH} # add the clang tool to env PATH
			fi
		done
		export PATH
	elif [[ -n $CROSS_COMPILE_TOOL ]]; then
		export CROSS_COMPILE=${CROSS_COMPILE_TOOL}
	fi

	# Have host compiler use LLD and compiler-rt.
	LLD_COMPILER_RT="-fuse-ld=lld --rtlib=compiler-rt"
	if [[ -n "${NDK_TRIPLE}" ]]; then
		NDK_DIR=${ROOT_DIR}/prebuilts/ndk-r23

		if [[ ! -d "${NDK_DIR}" ]]; then
			# Kleaf/Bazel will checkout the ndk to a different directory than
			# build.sh.
			NDK_DIR=${ROOT_DIR}/external/prebuilt_ndk
			if [[ ! -d "${NDK_DIR}" ]]; then
			echo "ERROR: NDK_TRIPLE set, but unable to find prebuilts/ndk." 1>&2
			echo "Did you forget to checkout prebuilts/ndk?" 1>&2
			exit 1
			fi
		fi
		USERCFLAGS="--target=${NDK_TRIPLE} "
		USERCFLAGS+="--sysroot=${NDK_DIR}/toolchains/llvm/prebuilt/linux-x86_64/sysroot "
		# Some kernel headers trigger -Wunused-function for unused static functions
		# with clang; GCC does not warn about unused static inline functions. The
		# kernel sets __attribute__((maybe_unused)) on such functions when W=1 is
		# not set.
		USERCFLAGS+="-Wno-unused-function "
		# To help debug these flags, consider commenting back in the following, and
		# add `echo $@ > /tmp/log.txt` and `2>>/tmp/log.txt` to the invocation of $@
		# in scripts/cc-can-link.sh.
		#USERCFLAGS+=" -Wl,--verbose -v"
		# We need to set -fuse-ld=lld for Android's build env since AOSP LLVM's
		# clang is not configured to use LLD by default, and BFD has been
		# intentionally removed. This way CC_CAN_LINK can properly link the test in
		# scripts/cc-can-link.sh.
		USERLDFLAGS="${LLD_COMPILER_RT} "
		USERLDFLAGS+="--target=${NDK_TRIPLE} "
	else
		USERCFLAGS="--sysroot=/dev/null"
	fi

	#setting_the_default_output_dir
	export COMMON_OUT_DIR=$(readlink -m ${OUT_DIR:-${ROOT_DIR}/out${OUT_DIR_SUFFIX}/${BRANCH}})
	export OUT_DIR=$(readlink -m ${COMMON_OUT_DIR}/${KERNEL_DIR})
	export DIST_DIR=$(readlink -m ${DIST_DIR:-${COMMON_OUT_DIR}/dist})
	export UNSTRIPPED_DIR=${DIST_DIR}/unstripped
	export UNSTRIPPED_MODULES_ARCHIVE=unstripped_modules.tar.gz
	export MODULES_ARCHIVE=modules.tar.gz
	export MODULES_STAGING_DIR=$(readlink -m ${COMMON_OUT_DIR}/staging)
	export MODULES_PRIVATE_DIR=$(readlink -m ${COMMON_OUT_DIR}/private)
	export KERNEL_UAPI_HEADERS_DIR=$(readlink -m ${COMMON_OUT_DIR}/kernel_uapi_headers)
	export INITRAMFS_STAGING_DIR=${MODULES_STAGING_DIR}/initramfs_staging
	export SYSTEM_DLKM_STAGING_DIR=${MODULES_STAGING_DIR}/system_dlkm_staging
	export VENDOR_DLKM_STAGING_DIR=${MODULES_STAGING_DIR}/vendor_dlkm_staging
	export MKBOOTIMG_STAGING_DIR="${MODULES_STAGING_DIR}/mkbootimg_staging"
	export OUT_AMLOGIC_DIR=$(readlink -m ${COMMON_OUT_DIR}/amlogic)

	tool_args+=("LOADADDR=0x108000")
	tool_args+=("DEPMOD=depmod")
	TOOL_ARGS="${tool_args[@]}"

	mkdir -p ${OUT_DIR}
	if [ "${SKIP_RM_OUTDIR}" != "1" ] ; then
		rm -rf ${COMMON_OUT_DIR}
	fi

	source ${ROOT_DIR}/build/kernel/build_utils.sh

	DTS_EXT_DIR=${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/arch/${ARCH}/boot/dts/amlogic
	DTS_EXT_DIR=$(rel_path ${ROOT_DIR}/${DTS_EXT_DIR} ${KERNEL_DIR})
	export dtstree=${DTS_EXT_DIR}
	export DTC_INCLUDE=${ROOT_DIR}/${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/include

	EXT_MODULES="
		${EXT_MODULES}
	"

	EXT_MODULES_CONFIG="
		${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/scripts/amlogic/ext_modules_config
	"

	EXT_MODULES_PATH="
		${KERNEL_DIR}/${COMMON_DRIVERS_DIR}/scripts/amlogic/ext_modules_path
	"

	POST_KERNEL_BUILD_CMDS="prepare_module_build"
	EXTRA_CMDS="extra_cmds"

	IN_KERNEL_MODULES=1
}
export -f set_default_parameters_for_32bit

function generating_test_mappings_zip () {
	echo "========================================================"
	echo " Generating test_mappings.zip"
	TEST_MAPPING_FILES=${OUT_DIR}/test_mapping_files.txt
	find ${ROOT_DIR} -name TEST_MAPPING \
	  -not -path "${ROOT_DIR}/\.git*" \
	  -not -path "${ROOT_DIR}/\.repo*" \
	  -not -path "${ROOT_DIR}/out*" \
	  > ${TEST_MAPPING_FILES}
	soong_zip -o ${DIST_DIR}/test_mappings.zip -C ${ROOT_DIR} -l ${TEST_MAPPING_FILES}
}
export -f generating_test_mappings_zip

