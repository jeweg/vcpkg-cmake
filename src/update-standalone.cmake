# Run the updates as a standalone script. In this case we read the config from disk
# and make it available to update.cmake just like the public api does when including it.

include(${CMAKE_CURRENT_LIST_DIR}/common.cmake)

vcm_dict_load(vcm_config ${_vcm_last_declared_config_file})

include(${CMAKE_CURRENT_LIST_DIR}/update.cmake)
