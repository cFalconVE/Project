*CLASS zcl_raw_utils DEFINITION
*  PUBLIC
*  FINAL
*  CREATE PUBLIC .
*
*  PUBLIC SECTION.
*  PROTECTED SECTION.
*  PRIVATE SECTION.
*ENDCLASS.
*
**
*
*CLASS zcl_raw_utils IMPLEMENTATION.
*ENDCLASS.

CLASS zcl_raw_utils DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    " Método estático para quitar ceros a la derecha
    CLASS-METHODS remove_trailing_zeros
      IMPORTING
        !iv_data        TYPE xstring
      RETURNING
        VALUE(rv_clean) TYPE xstring.

    " Sobrecarga para RAW fijo
    CLASS-METHODS remove_trailing_zeros_raw
      IMPORTING
        !iv_data        TYPE any
      RETURNING
        VALUE(rv_clean) TYPE xstring.

ENDCLASS.

CLASS zcl_raw_utils IMPLEMENTATION.

  METHOD remove_trailing_zeros.
*  " --- Para XSTRING ---
    DATA lv_len TYPE i.

    lv_len = xstrlen( iv_data ).
    rv_clean = iv_data.

*    WHILE lv_len > 0 AND rv_clean+lv_len-1(1) = '00'.
*      lv_len   = lv_len - 1.
*      rv_clean = rv_clean(lv_len).
*    ENDWHILE.
  ENDMETHOD.

  METHOD remove_trailing_zeros_raw.
    " --- Para RAW fijo ---
    DATA lv_xstr TYPE xstring.

    " Convertir RAW fijo a XSTRING
*    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
*      EXPORTING
*        input_length = xstrlen( iv_data )
*      IMPORTING
*        buffer       = lv_xstr
*      TABLES
*        binary_tab   = VALUE scms_t_binary( ( iv_data ) ).

    " Reutilizar el método principal
    rv_clean = remove_trailing_zeros( lv_xstr ).
  ENDMETHOD.

ENDCLASS.

