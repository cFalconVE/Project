*&---------------------------------------------------------------------*
*& Report  zerr_log_viewer_alv2
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zerr_log_viewer_alv2.

*TABLES: zerr_log.

" Parámetros de selección
PARAMETERS: p_fechai TYPE dats OBLIGATORY DEFAULT sy-datum,
            p_fechaf TYPE dats OBLIGATORY DEFAULT sy-datum.

SELECT-OPTIONS: so_user FOR sy-uname,
                so_tcode FOR sy-tcode.

DATA: lt_log TYPE TABLE OF zerr_app_log,
      lo_alv TYPE REF TO cl_salv_table.

START-OF-SELECTION.

  " Leer registros filtrados
  SELECT * FROM zerr_app_log
    INTO TABLE @lt_log
    WHERE erdat BETWEEN @p_fechai AND @p_fechaf
      AND erusr IN @so_user
      AND tcode IN @so_tcode
    ORDER BY erdat DESCENDING, erzet DESCENDING.

  IF sy-subrc <> 0.
    MESSAGE 'No se encontraron registros para los filtros indicados.' TYPE 'I'.
    EXIT.
  ENDIF.

  " Crear ALV
  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_alv
        CHANGING  t_table      = lt_log ).

      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->get_columns( )->set_optimize( abap_true ).
      lo_alv->get_display_settings( )->set_list_header(
        |Visor de Errores - { p_fechai } a { p_fechaf }| ).

      " Manejar doble clic
*      DATA(lo_events) = lo_alv->get_event( ).
*      SET HANDLER lcl_event_handler=>on_double_click FOR lo_events.
*
*      " Guardar datos para el handler
*      lcl_event_handler=>gt_log = lt_log.

      lo_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'E'.
  ENDTRY.

  "------------------------------------------------------------
  " Clase local para manejar eventos
  "------------------------------------------------------------
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA gt_log TYPE TABLE OF zerr_app_log.

    CLASS-METHODS on_double_click
                FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.

    CLASS-METHODS show_popup_detail
      IMPORTING is_log TYPE zerr_app_log.

    CLASS-METHODS export_to_txt
      IMPORTING is_log TYPE zerr_app_log.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.

  METHOD on_double_click.
    DATA(ls_log) = VALUE zerr_app_log( ).

    READ TABLE gt_log INTO ls_log INDEX row.
    IF sy-subrc = 0.
      show_popup_detail( ls_log ).
    ENDIF.
  ENDMETHOD.

  METHOD show_popup_detail.
    DATA: lt_text TYPE STANDARD TABLE OF string,
          lv_line TYPE string.

    APPEND |Fecha: { is_log-erdat } Hora: { is_log-erzet }| TO lt_text.
    APPEND |Usuario: { is_log-erusr }  TCode: { is_log-tcode }| TO lt_text.
    APPEND |Contexto: { is_log-context }| TO lt_text.
    APPEND |Mensaje: { is_log-message }| TO lt_text.

    "Mostrar popup con scroll
    CALL FUNCTION 'POPUP_WITH_TABLE_DISPLAY_OK'
      EXPORTING
        endpos_col = 120
        endpos_row = 20
        titletext  = 'Detalle del Error'
      TABLES
        valuetab   = lt_text.

    " Preguntar si exportar
    DATA lv_answer TYPE c.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar       = 'Exportar a TXT'
        text_question  = '¿Desea exportar este error a un archivo TXT?'
        text_button_1  = 'Sí'
        text_button_2  = 'No'
        default_button = '2'
      IMPORTING
        answer         = lv_answer.

    IF lv_answer = '1'.
      export_to_txt( is_log ).
    ENDIF.
  ENDMETHOD.

  METHOD export_to_txt.
    DATA: lt_file     TYPE STANDARD TABLE OF string,
          lv_fullpath TYPE string.

    APPEND |Fecha: { is_log-erdat } Hora: { is_log-erzet }| TO lt_file.

  ENDMETHOD.
ENDCLASS.
