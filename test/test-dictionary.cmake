include(${CMAKE_CURRENT_LIST_DIR}/../src/dictionary.cmake)

vcm_dict_print(foo)

function(foo)
	vcm_dict_set(foo a a1 test1)
	vcm_dict_set(foo a a2 test2)
endfunction()
foo()
vcm_dict_set(foo b a1 hello)
vcm_dict_set(foo b b1 foo)
vcm_dict_set(foo a a1 test3)
vcm_dict_append(foo a a1 test4)

message("----------------")
vcm_dict_print(foo)

vcm_dict_unset(foo a a2)

message("----------------")
vcm_dict_print(foo)

vcm_dict_unset(foo a a1)

message("----------------")
vcm_dict_print(foo)

vcm_dict_get(foo b a1 tmp)
message("b[a1] == ${tmp}")
vcm_dict_get(foo b b1 tmp)
message("b[b1] == ${tmp}")

message("----------------")

vcm_dict_set(bar b a1 hello)
vcm_dict_set(bar b b1 foox)
vcm_dict_set(bar b b2 foox)
vcm_dict_print(bar)

message("----------------1")

vcm_dict_equals(foo foo equals)
message("equals? ${equals}")

message("----------------2")

vcm_dict_equals(foo bar equals)
message("equals? ${equals}")

message("----------------3")

vcm_dict_unset(bar b b2)
vcm_dict_equals(foo bar equals)
message("equals? ${equals}")

message("----------------4")

vcm_dict_set(bar b b1 foo)
vcm_dict_equals(foo bar equals)
message("equals? ${equals}")
vcm_dict_print(bar)

message("----------------5")

vcm_dict_clear(foo)
vcm_dict_print(foo)
vcm_dict_set(foo b xxx yyy)
vcm_dict_print(foo)

get_directory_property(vars VARIABLES)
foreach(var IN LISTS vars)
	message(STATUS "${var}=\"${${var}}\"")
endforeach()
