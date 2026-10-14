*&---------------------------------------------------------------------*
*& Report  zerr_log_viewer_alv_popup
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zerr_log_viewer_alv_popup.

"------------------------------------------------------------
" Clase local para manejar eventos
"------------------------------------------------------------
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA gt_log TYPE TABLE OF zerr_app_log.

    CLASS-METHODS on_double_click
                FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD on_double_click.
    DATA(ls_log) = VALUE zerr_app_log( ).

    READ TABLE gt_log INTO ls_log INDEX row.

    IF sy-subrc = 0.
      " Mostrar popup con detalle
      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
        EXPORTING
          titel     = |Detalle del Error ({ ls_log-erdat } { ls_log-erzet })|
          textline1 = |Usuario: { ls_log-erusr }  TCode: { ls_log-tcode }|
          textline2 = |Contexto: { ls_log-context }|
          textline3 = |Mensaje: { ls_log-message }|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

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

      " Activar funciones estándar
      lo_alv->get_functions( )->set_all( abap_true ).

      " Ajustar columnas
      lo_alv->get_columns( )->set_optimize( abap_true ).

      " Título
      lo_alv->get_display_settings( )->set_list_header(
        |Visor de Errores - { p_fechai } a { p_fechaf }| ).

      " Manejar doble clic
      DATA(lo_events) = lo_alv->get_event( ).
*      DATA(lo_handler) = NEW lcl_event_handler( ).

      SET HANDLER lcl_event_handler=>on_double_click FOR lo_events.

      " Guardar datos en memoria para el handler

      lcl_event_handler=>gt_log = lt_log.

      " Mostrar ALV
      lo_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'E'.
  ENDTRY.
