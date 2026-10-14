CLASS zcl_runtime_info DEFINITION
  PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.

    CLASS-METHODS:
      get_current_class_method
        RETURNING
          VALUE(rv_call) TYPE string,

      get_current_location
        RETURNING VALUE(rv_location) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_runtime_info IMPLEMENTATION.
  METHOD get_current_class_method.
    DATA: lt_stack TYPE abap_callstack,
          ls_stack TYPE abap_callstack_line,
          lv_pos   TYPE i,
          lv_char  TYPE c1 VALUE '='.

    " Obtener la pila de ejecución
    CALL FUNCTION 'SYSTEM_CALLSTACK'
      IMPORTING
        callstack = lt_stack.

    " El índice 2 normalmente es el método que llamó a esta función
    READ TABLE lt_stack INDEX 2 INTO ls_stack.

    IF sy-subrc = 0.
      " Buscar la posición del carácter
      FIND lv_char IN ls_stack-mainprogram MATCH OFFSET lv_pos.

      IF sy-subrc = 0. " Si se encontró el carácter
        " Extraer desde el inicio hasta antes del carácter encontrado
        ls_stack-mainprogram = ls_stack-mainprogram(lv_pos).
      ENDIF.

      " Concatenar clase y método
      rv_call = |{ ls_stack-mainprogram }=>{ ls_stack-blockname }|.
    ELSE.
      rv_call = 'UNKNOWN_METHOD'.
    ENDIF.

  ENDMETHOD.

  METHOD get_current_location.

    DATA: lt_stack TYPE abap_callstack,
          ls_stack TYPE abap_callstack_line,
          lv_pos   TYPE i,
          lv_char  TYPE c1 VALUE '='.

    " Obtener la pila de ejecución
    CALL FUNCTION 'SYSTEM_CALLSTACK'
      IMPORTING
        callstack = lt_stack.

    " El índice 2 normalmente es el método que llamó a esta función
    READ TABLE lt_stack INDEX 2 INTO ls_stack.
    IF sy-subrc = 0.
      " Buscar la posición del carácter
      FIND lv_char IN ls_stack-mainprogram MATCH OFFSET lv_pos.

      IF sy-subrc = 0. " Si se encontró el carácter
        " Extraer desde el inicio hasta antes del carácter encontrado
        ls_stack-mainprogram = ls_stack-mainprogram(lv_pos).
      ENDIF.

      " Concatenar clase, método y línea
      rv_location = |{ ls_stack-mainprogram }=>{ ls_stack-blockname } (Línea { ls_stack-line })|.
    ELSE.
      rv_location = |UNKNOWN_LOCATION|.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
