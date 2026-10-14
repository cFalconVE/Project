*&---------------------------------------------------------------------*
*& Report  zerr_log_viewer_alv
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zerr_log_viewer_alv.

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

      " Activar funciones estándar (ordenar, filtrar, exportar)
      lo_alv->get_functions( )->set_all( abap_true ).

      " Ajustar columnas automáticamente
      lo_alv->get_columns( )->set_optimize( abap_true ).

      " Título del ALV
      lo_alv->get_display_settings( )->set_list_header(
        |Visor de Errores - { p_fechai } a { p_fechaf }| ).

      " Mostrar ALV
      lo_alv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'E'.
  ENDTRY.
