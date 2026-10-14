CLASS lcl_trans DEFINITION.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_response_item,
        code   TYPE string,
        title  TYPE string,
        detail TYPE string,
*        fecha  TYPE datum,
*        hora   TYPE sy-uzeit,
      END OF ty_response_item,

      tt_response_list TYPE STANDARD TABLE OF ty_response_item WITH EMPTY KEY,

      BEGIN OF ty_response,
        status  TYPE i,
        reason  TYPE string,
        fecha   TYPE datum,
        hora    TYPE sy-uzeit,
        message TYPE tt_response_list,
      END OF ty_response,

      tt_response TYPE ty_response.

    TYPES:
      BEGIN OF ty_endruta,
        tdocumento   TYPE ztdocumento,
        nrodocumento TYPE tknum,
        fecha_fin    TYPE string,
        hora_fin     TYPE string,
      END OF ty_endruta.

    DATA: mv_tplst TYPE tplst READ-ONLY.

    DATA:
      lt_resp_list TYPE tt_response_list,
      ls_resp_item TYPE ty_response_item,
      ls_resp      TYPE ty_response.

    DATA: lv_status_code TYPE i VALUE 400, " Código HTTP
          lv_reason      TYPE string VALUE 'Bad Request'.

    METHODS:
      constructor
        IMPORTING
          iv_tplst TYPE tplst,

      save_end_ruta
        IMPORTING
          is_findesp        TYPE ty_endruta
        EXPORTING
          ev_code           TYPE i
          ev_reason         TYPE string
          ev_json           TYPE string
        CHANGING
          et_resp_list      TYPE tt_response_list
        RETURNING
          VALUE(rv_rerturn) TYPE abap_bool,

      save_ini_ruta_or
        IMPORTING
          is_desp           TYPE ty_endruta
        EXPORTING
          ev_code           TYPE i
          ev_reason         TYPE string
          ev_json           TYPE string
        CHANGING
          et_resp_list      TYPE tt_response_list
        RETURNING
          VALUE(rv_rerturn) TYPE abap_bool..

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA:
    lo_json    TYPE REF TO /ui2/cl_json.

    METHODS:
      commit_work.

ENDCLASS.

CLASS lcl_trans IMPLEMENTATION.

  METHOD constructor.
    mv_tplst = iv_tplst.
  ENDMETHOD.

  METHOD commit_work.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

  METHOD save_end_ruta.
    DATA: ls_gck    TYPE zsd_tb_gck,
          lv_date   TYPE sy-datum,
          lv_hours  TYPE sy-uzeit,
          iv_posnr  TYPE posnr VALUE 10,
          lv_result TYPE c LENGTH 1.

    CLEAR lt_resp_list.

*    lv_date = |{ is_findesp-fecha_fin+0(4) }{ is_findesp-fecha_fin+5(2) }{ is_findesp-fecha_fin+8(2) }|.
    lv_date = |{ is_findesp-fecha_fin+6(4) }{ is_findesp-fecha_fin+3(2) }{ is_findesp-fecha_fin+0(2) }|.
    lv_hours = |{ is_findesp-hora_fin+0(2) }{ is_findesp-hora_fin+3(2) }{ is_findesp-hora_fin+6(2) }|.

*    CHECK NOT it_incid[] IS INITIAL.
    lv_status_code = 422.
    lv_reason = 'Error de Data'.

    IF is_findesp-tdocumento NE 'GC'.
      ls_resp_item = VALUE #(
          code = |E-{ lv_status_code }|
          title = |Tipo de documento no válido|
          detail = |El tipo de documento { is_findesp-tdocumento } no es válido| ).
*          fecha = sy-datum
*          hora = sy-uzeit

      APPEND ls_resp_item TO et_resp_list.
    ENDIF.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = lv_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.

    IF sy-subrc NE 0.
      ls_resp_item = VALUE #(
           code = |E-{ lv_status_code }|
           title = |Formato de la fecha no valido|
           detail = |la fecha { is_findesp-fecha_fin } no es valida| ).

      APPEND ls_resp_item TO et_resp_list.
    ENDIF.

    CALL FUNCTION 'TIME_CHECK_PLAUSIBILITY'
      EXPORTING
        time                      = lv_hours    " Hora a verificar
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.

    IF sy-subrc NE 0.
      ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Formato de la hora no valido|
            detail = |La hora { is_findesp-hora_fin } no válida| ).

      APPEND ls_resp_item TO et_resp_list.
    ENDIF.

    IF is_findesp-nrodocumento IS INITIAL.
      ls_resp_item = VALUE #(
          code = |E-{ lv_status_code }|
          title = |Número de documento está vacío|
          detail = |El número de documento está vacío| ).

      APPEND ls_resp_item TO et_resp_list.
    ELSE.
      SELECT SINGLE *
        INTO ls_gck
        FROM zsd_tb_gck
        WHERE tplst = mv_tplst AND
*              tdocumento EQ is_findesp-tdocumento AND
              tknum EQ is_findesp-nrodocumento.

      IF sy-subrc NE 0.
        lv_status_code = 401.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Número de documento no existe|
            detail = |El número de documento { is_findesp-nrodocumento } no exite| ).

        APPEND ls_resp_item TO et_resp_list.
      ELSE.
        lv_status_code = 201.
        IF ls_gck-fec_fin IS NOT INITIAL AND
           ls_gck-hora_fin IS NOT INITIAL.
          ls_resp_item = VALUE #(
             code = |OK-{ lv_status_code }|
             title = |Número de documento cerrado|
             detail = |El número de documento { is_findesp-nrodocumento } ya fue actualizado anteriormente| ).

          APPEND ls_resp_item TO et_resp_list.
        ELSE.

          UPDATE zsd_tb_gck
             SET usr_fin = @sy-uname, fec_fin = @lv_date, hora_fin = @lv_hours
           WHERE tplst = @mv_tplst AND
*                 tdocumento = @is_findesp-tdocumento AND
                 tknum = @is_findesp-nrodocumento.

          IF sy-subrc NE 0.
            ls_resp_item = VALUE #(
                code = |E-{ lv_status_code }|
                title = |No se pudo actualizar la data|
                detail = |El número de documento { is_findesp-nrodocumento } no se actualizo| ).

            APPEND ls_resp_item TO et_resp_list.
          ELSE.

            DATA(ls_stage) = VALUE zsd_st_stage(
                  tknum      = ls_gck-tknum
                  sttrg      = 7
                  date_stage = lv_date
                  time_stage = lv_hours ).

            IF zcl_sd_stat_transp=>update_stage( is_transp = ls_stage ) EQ abap_false.

*            UPDATE vttk
*                SET stten = 'X'
*                    daten = lv_date
*                    uaten = lv_hours
*                    WHERE tknum = ls_gck-tknum.

*          IF sy-subrc EQ 0.
*            commit_work( ).
              ls_resp_item = VALUE #(
                             code = |E-{ lv_status_code }|
                             title = |No se pudo actualizar la data|
                             detail = |El despacho { is_findesp-nrodocumento } no actualizo el fin de ruta { ls_stage-sttrg }| ).

              APPEND ls_resp_item TO et_resp_list.
*      ELSE.
*        roolback_work( ).
*        RETURN.
            ENDIF.

            ls_resp_item = VALUE #(
                          code = '200'
                          title = |Se actualizó la guía de despacho|
                          detail = |El cierre de la Guía de despacho { is_findesp-nrodocumento } con éxito| ).
            lv_status_code = 200.
            lv_reason = 'OK'.
            rv_rerturn = abap_true.

            APPEND ls_resp_item TO et_resp_list.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

*    " Armar respuesta
*    ls_resp = VALUE #(
*        status = lv_status_code
*        reason = lv_reason
*        fecha = sy-datum
*        hora = sy-uzeit
*        message = lt_resp_list ).

    ev_code = lv_status_code.
    ev_reason = lv_reason.

*    ev_json = lo_json->serialize(
*                  EXPORTING
*                    data        = ls_resp
*                    pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

*    zcl_json_utility=>convert_stuct_to_json(
*        EXPORTING
*            im_s_data = ls_resp
*            im_v_case = zcl_json_utility=>co_ftype_camelcase
*        RECEIVING
*            rt_v_json = ev_json ).

  ENDMETHOD.

  METHOD save_ini_ruta_or.
    DATA: ls_gck    TYPE zsd_tb_gck,
          lv_date   TYPE sy-datum,
          lv_hours  TYPE sy-uzeit,
          iv_posnr  TYPE posnr VALUE 10,
          lv_result TYPE c LENGTH 1.

    CLEAR lt_resp_list.

    lv_date = |{ is_desp-fecha_fin+6(4) }{ is_desp-fecha_fin+3(2) }{ is_desp-fecha_fin+0(2) }|.
    lv_hours = |{ is_desp-hora_fin+0(2) }{ is_desp-hora_fin+3(2) }{ is_desp-hora_fin+6(2) }|.

*    CHECK NOT it_incid[] IS INITIAL.
    lv_status_code = 422.
    lv_reason = 'Error de Data'.

*    IF is_desp-tdocumento NE 'GC'.
*      ls_resp_item = VALUE #(
*          code = |E-{ lv_status_code }|
*          title = |Tipo de documento no válido|
*          detail = |El tipo de documento { is_desp-tdocumento } no es válido| ).
*
*      APPEND ls_resp_item TO et_resp_list.
*    ENDIF.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = lv_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.

    IF sy-subrc NE 0.
      ls_resp_item = VALUE #(
           code = |E-{ lv_status_code }|
           title = |Formato de la fecha no valido|
           detail = |la fecha { is_desp-fecha_fin } no es valida| ).

      APPEND ls_resp_item TO et_resp_list.
    ENDIF.

    CALL FUNCTION 'TIME_CHECK_PLAUSIBILITY'
      EXPORTING
        time                      = lv_hours    " Hora a verificar
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.

    IF sy-subrc NE 0.
      ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Formato de la hora no valido|
            detail = |La hora { is_desp-hora_fin } no válida| ).

      APPEND ls_resp_item TO et_resp_list.
    ENDIF.

    IF is_desp-nrodocumento IS INITIAL.
      ls_resp_item = VALUE #(
          code = |E-{ lv_status_code }|
          title = |Número de documento está vacío|
          detail = |El número de documento está vacío| ).

      APPEND ls_resp_item TO et_resp_list.
    ELSE.
      SELECT SINGLE *
        INTO ls_gck
        FROM zsd_tb_gck
        WHERE tplst = mv_tplst AND
              tdocumento EQ 'GD' AND
              tknum EQ is_desp-nrodocumento.

      IF sy-subrc NE 0.
        lv_status_code = 401.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Número de documento no existe|
            detail = |El número de documento { is_desp-nrodocumento } no exite| ).

        APPEND ls_resp_item TO et_resp_list.
      ELSE.
        lv_status_code = 201.

        IF ls_gck-fec_fin IS NOT INITIAL AND
           ls_gck-hora_fin IS NOT INITIAL.
          ls_resp_item = VALUE #(
             code = |OK-{ lv_status_code }|
             title = |Ruta de retiro|
             detail = |La Orden de Retiro { is_desp-nrodocumento } ya fue actualizado anteriormente| ).

          APPEND ls_resp_item TO et_resp_list.
        ELSE.

          UPDATE zsd_tb_gck
             SET usr_exit = @sy-uname, fec_exit = @lv_date, hora_exit = @lv_hours
           WHERE tplst = @mv_tplst AND
*                 tdocumento = @is_findesp-tdocumento AND
                 tknum = @is_desp-nrodocumento.

          IF sy-subrc NE 0.
            ls_resp_item = VALUE #(
                code = |E-{ lv_status_code }|
                title = |No se pudo actualizar la data|
                detail = |El número de documento { is_desp-nrodocumento } no se actualizo| ).

            APPEND ls_resp_item TO et_resp_list.
          ELSE.

*            UPDATE vttk
*                SET stten = 'X'
*                    daten = lv_date
*                    uaten = lv_hours
*                    WHERE tknum = ls_gck-tknum.

            commit_work( ).

            ls_resp_item = VALUE #(
                          code = '200'
                          title = |Se actualizó el despacho Ordenes de Retiro|
                          detail = |Se actualizó el incio del despacho de OR { is_desp-nrodocumento } con éxito| ).
            lv_status_code = 200.
            lv_reason = 'OK'.
            rv_rerturn = abap_true.

            APPEND ls_resp_item TO et_resp_list.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

*    " Armar respuesta
*    ls_resp = VALUE #(
*        status = lv_status_code
*        reason = lv_reason
*        fecha = sy-datum
*        hora = sy-uzeit
*        message = lt_resp_list ).

    ev_code = lv_status_code.
    ev_reason = lv_reason.

*    ev_json = lo_json->serialize(
*                  EXPORTING
*                    data        = ls_resp
*                    pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

*    zcl_json_utility=>convert_stuct_to_json(
*        EXPORTING
*            im_s_data = ls_resp
*            im_v_case = zcl_json_utility=>co_ftype_camelcase
*        RECEIVING
*            rt_v_json = ev_json ).

  ENDMETHOD.

ENDCLASS.

CLASS lcl_seguridad_web DEFINITION.

  PUBLIC SECTION.
    DATA: mv_header TYPE tihttpnvp READ-ONLY,
          mv_return TYPE abap_bool VALUE abap_false READ-ONLY.

    CONSTANTS:
      mc_url TYPE string VALUE 'https://qa.grupocorimon.com:8443/sap/bc/rest/z_despacho_dig/'.

    METHODS:
      constructor
        IMPORTING  iv_header TYPE tihttpnvp
        EXCEPTIONS error_unauthorized,

      check_web
*        IMPORTING
*          iv_header        TYPE tihttpnvp
        RETURNING
          VALUE(rv_return) TYPE abap_bool
        EXCEPTIONS
          error_unauthorized.

  PROTECTED SECTION.

  PRIVATE SECTION.

*    METHODS:
*      check_web
*        IMPORTING
*          iv_header        TYPE tihttpnvp
*        RETURNING
*          VALUE(rv_return) TYPE abap_bool
*        EXCEPTIONS
*          error_unauthorized.

ENDCLASS.

CLASS lcl_seguridad_web IMPLEMENTATION.

  METHOD constructor.
    mv_header = iv_header.

  ENDMETHOD.

  METHOD check_web.
    DATA: it_inputparams TYPE tihttpnvp,
          ls_inputparams TYPE LINE OF tihttpnvp.

    FIELD-SYMBOLS <fs_param> TYPE LINE OF tihttpnvp.

    CLEAR ls_inputparams.

    READ TABLE mv_header INTO ls_inputparams WITH KEY name = 'soc'.

*    IF sy-subrc EQ 0.
*
*    ENDIF.

    CHECK sy-subrc EQ 0.

*    lv_bukrs = ls_inputparams-value .
*
*    CLEAR: ls_header_field.
*    UNASSIGN <fs_param>.
*
*    LOOP AT lv_header ASSIGNING <fs_param>.
*
*      IF <fs_param>-name = 'origin' AND <fs_param>-value IS NOT INITIAL.
*        ls_header_field-name  = <fs_param>-name.
*        ls_header_field-value = <fs_param>-value.
*      ENDIF.
*
*      CASE <fs_param>-name.
*        WHEN 'bukrs'.
*          lv_bukrs = <fs_param>-value .
*        WHEN 'kunnr' .
*          lv_kunnr = <fs_param>-value .
*        WHEN 'budat'.
*          lv_budat = <fs_param>-value .
*        WHEN 'timlo'.
*          lv_timlo = <fs_param>-value .
*        WHEN 'corimon'.
*          lv_crm   = <fs_param>-value .
*        WHEN OTHERS.
*      ENDCASE.
*
*    ENDLOOP.
*
*    SELECT SINGLE *
*      FROM zfi_dominios_val
*      INTO wa_dominios
*      WHERE bukrs = lv_bukrs.
*
*    ls_dompostman = wa_dominios-domipostman.
*    ls_domtest = wa_dominios-dominiotest.
*    ls_domprd = wa_dominios-dominioprod.
*
**    TRY.
*
*    IF ls_header_field-value IS INITIAL.
*      ls_header_field = lv_header[ name = '~remote_addr' ].
*    ENDIF.
*
*    CASE ls_header_field-value .
*      WHEN ls_dompostman .
*      WHEN ls_domtest.
*      WHEN ls_domprd.
*      WHEN OTHERS.
*        RAISE error_unauthorized.
*    ENDCASE.
*
*    CALL FUNCTION 'ZARFM_GENERA_VALOR'
*      EXPORTING
*        parm1 = lv_bukrs
*        parm2 = lv_kunnr
*        parm3 = lv_budat
*        parm4 = lv_timlo
*      IMPORTING
*        parm5 = lv_crm1.
*    IF lv_crm NE lv_crm1  .
*      RAISE error_unauthorized.
*    ENDIF.

    rv_return = abap_true.

  ENDMETHOD.

ENDCLASS.
