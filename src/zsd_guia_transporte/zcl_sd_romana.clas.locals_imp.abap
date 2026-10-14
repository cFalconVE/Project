CLASS lcl_romana DEFINITION.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_pesaje,
        peso_tara  TYPE i,
        hora_tara  TYPE string, "timestamp,
        peso_bruto TYPE i,
        hora_bruto TYPE string, "timestamp,
        peso_neto  TYPE i,
        diferencia TYPE i,
      END OF ty_pesaje,

      BEGIN OF ty_transporte,
        numguia             TYPE tknum,
        nacionalidad        TYPE c LENGTH 1,
        cedula              TYPE zciconductor,
        empresa             TYPE zname1,
        placa               TYPE zplvehiculo,
        marca               TYPE zzvehiculo,
        modelo              TYPE ztipovehiculo,
        numero_pase         TYPE i,
        motivo              TYPE zmotivo,
        hora_salida_planta  TYPE string, "timestamp,
        hora_entrada_planta TYPE string, "timestamp,
        datos_pesaje        TYPE STANDARD TABLE OF ty_pesaje
            WITH EMPTY KEY, "TYPE ty_pesaje
      END OF ty_transporte,

      tt_transporte TYPE STANDARD TABLE OF ty_transporte,

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

      tt_response TYPE ty_response,

      BEGIN OF ty_driver,
        nacionalidad TYPE z_nacionalidad,
        cedula       TYPE zciconductor,
        nombre       TYPE znom_driver,
        apellido     TYPE zape_driver,
        telefono     TYPE telf1,
        email        TYPE zcorreo,
      END OF ty_driver,

      BEGIN OF ty_log,
        tplst   TYPE tplst,
        proceso TYPE char3,
        json    TYPE string,
      END OF ty_log,

      tt_json TYPE STANDARD TABLE OF ty_log,

      BEGIN OF ty_ambiente,
        sysid   TYPE sy-sysid,
        url     TYPE zurl,
        api_key TYPE string,
      END OF ty_ambiente.



    CLASS-DATA:
        mt_drivers TYPE HASHED TABLE OF ty_driver
           WITH UNIQUE KEY cedula.

    DATA:
      mv_tplst  TYPE tplst READ-ONLY,
      mv_cedula TYPE zciconductor READ-ONLY,
      ms_innovo TYPE zsd_st_serv_url. "ty_ambiente.

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
*          is_innovo TYPE ty_ambiente,

      load_data
        IMPORTING
                  iv_cedula        TYPE zciconductor
        EXPORTING
                  es_resp_item     TYPE ty_response_item
*        CHANGING
*                  rt_resp_list     TYPE tt_response_list
        RETURNING VALUE(rv_return) TYPE abap_bool,

      save_conductores
        IMPORTING iv_              TYPE string
        RETURNING VALUE(ev_return) TYPE abap_bool,

      save_entrada
        IMPORTING
          is_romana        TYPE ty_transporte
        EXPORTING
          ev_code          TYPE i
          ev_reason        TYPE string
          ev_json          TYPE string
          es_resp          TYPE ty_response
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      save_salida
        IMPORTING
          is_romana        TYPE ty_transporte
        EXPORTING
          ev_code          TYPE i
          ev_reason        TYPE string
          ev_json          TYPE string
          es_resp          TYPE ty_response
          es_romak         TYPE zsd_tb_romanak
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      save_pesaje
        IMPORTING
          is_romana        TYPE ty_transporte
          is_pesaje        TYPE zsd_tb_romanap
        EXPORTING
          ev_code          TYPE i
          ev_reason        TYPE string
          ev_json          TYPE string
*          es_resp          TYPE ty_response
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

*      save_salida
*        IMPORTING
*          is_romana         TYPE ty_transporte
*        EXPORTING
*          ev_code           TYPE i
*          ev_reason         TYPE string
*          ev_json           TYPE string
*        RETURNING
*          VALUE(rv_rerturn) TYPE abap_bool,

*      save_pesada
*        IMPORTING
*          is_romana         TYPE ty_transporte
*        EXPORTING
*          ev_code           TYPE i
*          ev_reason         TYPE string
*          ev_json           TYPE string
*        RETURNING
*          VALUE(rv_rerturn) TYPE abap_bool,

      check_transp
        IMPORTING
                  iv_tknum         TYPE tknum
                  iv_actividad     TYPE char3
        RETURNING VALUE(rv_return) TYPE abap_bool,

      save_cond_guia
        IMPORTING
                  is_transporte    TYPE ty_transporte
        CHANGING
                  rt_resp_list     TYPE tt_response_list
        RETURNING VALUE(rv_return) TYPE abap_bool,

      save_pesaje_guia
        IMPORTING
                  is_transporte    TYPE ty_transporte
                  is_pesaje        TYPE zsd_tb_romanap
        CHANGING
                  rt_resp_list     TYPE tt_response_list
        RETURNING VALUE(rv_return) TYPE abap_bool,

      valid_data
        IMPORTING
                  is_transporte    TYPE ty_transporte
                  iv_actividad     TYPE char3
        EXPORTING
                  ev_code          TYPE i
                  ev_reason        TYPE string
                  es_resp          TYPE ty_response
                  es_stage         TYPE zsd_st_stage
*                  et_resp          TYPE tt_response_list
        CHANGING
                  et_resp_list     TYPE tt_response_list
        RETURNING VALUE(rv_return) TYPE abap_bool,

      valid_pesada
        IMPORTING
                  is_transporte    TYPE ty_transporte
        EXPORTING
                  ev_code          TYPE i
                  ev_reason        TYPE string
*                  es_resp          TYPE ty_response
        CHANGING
                  es_pesaje        TYPE zsd_tb_romanap
                  et_resp_list     TYPE tt_response_list
        RETURNING VALUE(rv_return) TYPE abap_bool,

      send_salida_transp
        IMPORTING
                  is_romak         TYPE zsd_tb_romanak
        CHANGING
*          es_pesaje    TYPE zsd_tb_romanap
                  et_resp_list     TYPE tt_response_list
        RETURNING VALUE(rv_return) TYPE abap_bool.

*      upd_guia
*        IMPORTING
*                  is_romak         TYPE zsd_tb_romanak
*        CHANGING
*                  et_resp_list     TYPE tt_response_list
*        RETURNING VALUE(rv_return) TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_text,
        tdid     TYPE tdid,
        tdobject TYPE tdobject,
        tdname   TYPE tdobname,
      END OF ty_text.

    CONSTANTS:
      lc_object   TYPE tdobject VALUE 'VTTK',
      lc_spras(1) TYPE c VALUE 'S'.

    DATA:
        ls_text TYPE ty_text.

    METHODS:
      commit_work,

      roolback_work,

      save_texto
        IMPORTING
                  is_thead         TYPE thead
                  is_tline         TYPE tline
                  iv_mensaje       TYPE string
        CHANGING
                  rt_resp_list     TYPE tt_response_list
        RETURNING VALUE(rv_return) TYPE abap_bool.

ENDCLASS.

CLASS lcl_romana IMPLEMENTATION.

  METHOD save_conductores.

  ENDMETHOD.

  METHOD constructor.
    mv_tplst = iv_tplst.

    DATA(lo_serv_url) = NEW zcl_sd_serv_digital( ).

    ms_innovo = VALUE #( sysid = sy-sysid
                         bukrs = mv_tplst
                         servicio = 'INNOVO' ).

    lo_serv_url->init( is_service = ms_innovo ).

    lo_serv_url->get_services(
      CHANGING
        es_service = ms_innovo ).

*    CASE sy-sysid.
*      WHEN 'DR3' OR 'QR3'.
*        ms_innovo = VALUE #(
*          sysid = sy-sysid
*          url = |https://qacorimon.innovologistic.innovosite.com/api/v1/integrations|
*          api_key = |l8UIhsE9OJWFpmgFSHzbTsFTBsexPLFpSwYJAdSv| ).
*      WHEN 'PR3'.
*        ms_innovo = VALUE #(
*          sysid = sy-sysid
*          url = |https://corimon.innovologistic.innovosite.com/api/v1/integrations|
*          api_key = |DDNrJm698bE3nmNuNY2qPcFumqGjWGVPQuN06tJJ| ).
*    ENDCASE.

*    IF sy-sysid EQ 'QR3'.
*      ms_innovo = VALUE #(
*          sysid = sy-sysid
*          url = |https://qacorimon.innovologistic.innovosite.com/api/v1/integrations|
*          api_key = |l8UIhsE9OJWFpmgFSHzbTsFTBsexPLFpSwYJAdSv| ).
*    ELSE.
*      ms_innovo = VALUE #(
*         sysid = sy-sysid
*         url = |https://corimon.innovologistic.innovosite.com/api/v1/integrations|
*         api_key = |DDNrJm698bE3nmNuNY2qPcFumqGjWGVPQuN06tJJ| ).
*
*    ENDIF.

*    UPDATE zsd_tb_drivers
*    SET nacionalidad = 'V'.

  ENDMETHOD.

  METHOD save_entrada.
    DATA: ls_gck    TYPE zsd_tb_gck,
          lv_date   TYPE sy-datum,
          lv_hours  TYPE sy-uzeit,
          iv_posnr  TYPE posnr VALUE 10,
          lv_result TYPE c LENGTH 1,
          ls_romk   TYPE zsd_tb_romanak,
          ls_romp   TYPE zsd_tb_romanap,
          lt_romk   TYPE STANDARD TABLE OF zsd_tb_romanak,
          lt_romp   TYPE STANDARD TABLE OF zsd_tb_romanap.

*    rv_return = valid_data(
*       EXPORTING
*         is_transporte = is_romana
*       IMPORTING
*         es_resp       = es_resp
*         et_resp       = et_resp_list
**          RECEIVING
**            rv_return     = rv_return
*     ).

    ev_code = 421.
    ev_reason = |Error en los datos|.

*    CHECK rv_return EQ abap_true.

    lv_date = |{ is_romana-hora_entrada_planta+0(4) }{ is_romana-hora_entrada_planta+5(2) }{ is_romana-hora_entrada_planta+8(2) }|.
    lv_hours = |{ is_romana-hora_entrada_planta+11(2) }{ is_romana-hora_entrada_planta+14(2) }{ is_romana-hora_entrada_planta+17(2) }|.

    ls_romk = VALUE
        #( tplst         = mv_tplst
           tknum         = is_romana-numguia
           nacionalidad  = is_romana-nacionalidad
           cedula        = is_romana-cedula
           empresa       = is_romana-empresa
           placa         = is_romana-placa
           marca         = is_romana-marca
           modelo        = is_romana-modelo
           numero_pase   = is_romana-numero_pase
           motivo        = is_romana-motivo
           fecha_entrada = lv_date
           hora_entrada  = lv_hours ).

    INSERT zsd_tb_romanak FROM ls_romk.

    IF sy-subrc = 0.
      lv_status_code = 200.
      lv_reason = 'OK'.
      ls_resp_item = VALUE #(
            code = |{ lv_reason }-{ lv_status_code }|
            title = |Guardado con éxito|
            detail = |La entrada del transporte:{ ls_romk-tknum } se guardo con exito| ).

      APPEND ls_resp_item TO et_resp_list.
    ELSE.
      lv_status_code = 201.
      lv_reason = 'Registro creado'.
      ls_resp_item = VALUE #(
            code = |OK-{ lv_status_code }|
            title = |Consulta|
            detail = |La entrada del transporte:{ ls_romk-tknum } ya existe| ).

      APPEND ls_resp_item TO et_resp_list.

*      MODIFY zsd_tb_romanak FROM ls_romk.

      UPDATE zsd_tb_romanak
         SET nacionalidad  = ls_romk-nacionalidad
             cedula        = ls_romk-cedula
             empresa       = ls_romk-empresa
             placa         = ls_romk-placa
             marca         = ls_romk-marca
             modelo        = ls_romk-modelo
             numero_pase   = ls_romk-numero_pase
             motivo        = ls_romk-motivo
             fecha_entrada = ls_romk-fecha_entrada
             hora_entrada  = ls_romk-hora_entrada
       WHERE tplst = ls_romk-tplst AND
             tknum = ls_romk-tknum.

      IF sy-subrc EQ 0.
        lv_status_code = 201.
        lv_reason = 'Registro actualizado'.
        ls_resp_item = VALUE #(
              code = |OK-{ lv_status_code }|
              title = |Actualizado transporte|
              detail = |La entrada del transporte:{ ls_romk-tknum } se actualizo| ).

        APPEND ls_resp_item TO et_resp_list.
      ENDIF.

    ENDIF.

    commit_work( ).

    ev_code = lv_status_code.
    ev_reason = lv_reason.
*    ls_romk = VALUE #( tknum )
*    et_resp_list = lt_resp_list.

    IF lv_status_code EQ 200 OR
       lv_status_code EQ 201.
      rv_return = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD save_salida.
    DATA: ls_gck    TYPE zsd_tb_gck,
          lv_date   TYPE sy-datum,
          lv_hours  TYPE sy-uzeit,
*          iv_posnr  TYPE posnr VALUE 10,
          lv_result TYPE c LENGTH 1,
*          ls_romk   TYPE zsd_tb_romanak,
*          ls_romp   TYPE zsd_tb_romanap,
          lt_romk   TYPE STANDARD TABLE OF zsd_tb_romanak.
*          lt_romp   TYPE STANDARD TABLE OF zsd_tb_romanap.

    ev_code = 421.
    ev_reason = |Error en los datos|.

*    CHECK rv_return EQ abap_true.

    lv_date = |{ is_romana-hora_salida_planta+0(4) }{ is_romana-hora_salida_planta+5(2) }{ is_romana-hora_salida_planta+8(2) }|.
    lv_hours = |{ is_romana-hora_salida_planta+11(2) }{ is_romana-hora_salida_planta+14(2) }{ is_romana-hora_salida_planta+17(2) }|.

    es_romak = VALUE
        #( tplst         = mv_tplst
           tknum         = is_romana-numguia
           fecha_salida = lv_date
           hora_salida  = lv_hours ).

    UPDATE zsd_tb_romanak
      SET fecha_salida = lv_date
          hora_salida = lv_hours
     WHERE tknum EQ is_romana-numguia.

    IF sy-subrc = 0.
      lv_status_code = 200.
      lv_reason = 'OK'.
      ls_resp_item = VALUE #(
            code = |{ lv_reason }-{ lv_status_code }|
            title = |Actualizado con éxito|
            detail = |La salida del transporte:{ es_romak-tknum } se guardo con exito| ).

      APPEND ls_resp_item TO et_resp_list.
    ELSE.
      lv_status_code = 404.
      lv_reason = 'No existe transporte'.
      ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |No existe transporte|
            detail = |El transporte:{ es_romak-tknum } no exite| ).

      APPEND ls_resp_item TO et_resp_list.

    ENDIF.

    ev_code = lv_status_code.
    ev_reason = lv_reason.
*    ls_romk = VALUE #( tknum )
*    et_resp_list = lt_resp_list.

    IF lv_status_code EQ 200.
      commit_work( ).
      rv_return = abap_true.
    ENDIF.

  ENDMETHOD.

*  METHOD save_pesada.
*
*  ENDMETHOD.

  METHOD check_transp.
*    DATA lv_tknum TYPE tknum.
*
*    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*      EXPORTING
*        input  = iv_tknum
*      IMPORTING
*        output = lv_tknum.

    CASE iv_actividad.
      WHEN 'E'.
        SELECT SINGLE tknum
          FROM vttk
          INTO @DATA(wa_tknum)
         WHERE tknum = @iv_tknum.
      WHEN 'P'.
        SELECT SINGLE r~tknum
          FROM vttk AS k
          INNER JOIN zsd_tb_romanak AS r
            ON k~tknum EQ r~tknum
          INTO @wa_tknum
         WHERE k~tknum = @iv_tknum.
      WHEN 'S'.
        SELECT SINGLE tknum
         INTO @wa_tknum
         FROM zsd_tb_gck
        WHERE tknum = @iv_tknum.
      WHEN 'OR'.
        SELECT SINGLE tknum
         INTO @wa_tknum
         FROM zsd_tb_gck
        WHERE tknum = @iv_tknum AND
              tdocumento = 'GD'.
    ENDCASE.

    CHECK sy-subrc EQ 0.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD valid_data.
    DATA:
*          ls_gck   TYPE zsd_tb_gck,
      lv_date  TYPE sy-datum,
      lv_hours TYPE sy-uzeit.

    DATA lt_det_romana TYPE STANDARD TABLE OF zsd_tb_romanap.

*    lt_det_romana[] = is_transporte-datos_pesaje[].

    CLEAR lt_resp_list.

    lv_status_code = 422.

    SELECT SINGLE tdocumento, tknum, env_desp
      FROM zsd_tb_gck
      INTO @DATA(ls_type_transp)
     WHERE tknum EQ @is_transporte-numguia.

    CASE iv_actividad.
      WHEN 'E'. "Entrada Transporte GC

        lv_date = |{ is_transporte-hora_entrada_planta+0(4) }{ is_transporte-hora_entrada_planta+5(2) }{ is_transporte-hora_entrada_planta+8(2) }|.
        lv_hours = |{ is_transporte-hora_entrada_planta+11(2) }{ is_transporte-hora_entrada_planta+14(2) }{ is_transporte-hora_entrada_planta+17(2) }|.

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
               detail = |la fecha de entrada { is_transporte-hora_entrada_planta+0(10) } no es valida| ).

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
                  detail = |La hora de entrada { is_transporte-hora_entrada_planta+11(8) } no es valida| ).

          APPEND ls_resp_item TO et_resp_list.
        ENDIF.

        CASE ls_type_transp-tdocumento.
          WHEN 'RXP'.

            es_stage = VALUE #(
               tdocumento = ls_type_transp-tdocumento
               tknum = is_transporte-numguia
               sttrg = '6'
               date_stage = lv_date
               time_stage = lv_hours ).

          WHEN OTHERS.

            IF is_transporte-empresa IS INITIAL.
              ls_resp_item = VALUE #(
                  code = |E-{ lv_status_code }|
                  title = |La empresa está vacía|
                  detail = |La empresa de transporte está vacío| ).

              APPEND ls_resp_item TO et_resp_list.
            ENDIF.

            IF is_transporte-placa IS INITIAL.
              ls_resp_item = VALUE #(
                  code = |E-{ lv_status_code }|
                  title = |Placa del vehiculo está vacía|
                  detail = |La placa del vehicui está vacío| ).

              APPEND ls_resp_item TO et_resp_list.
            ENDIF.

            IF is_transporte-marca IS INITIAL.
              ls_resp_item = VALUE #(
                  code = |E-{ lv_status_code }|
                  title = |Marca del vehiculo esta vacia|
                  detail = |La marca del vehiculo est vacio| ).

              APPEND ls_resp_item TO et_resp_list.
            ENDIF.

            IF is_transporte-numero_pase IS INITIAL.
              ls_resp_item = VALUE #(
                  code = |E-{ lv_status_code }|
                  title = |Numero del pase esta vacio|
                  detail = |Numero del pase esta vacio| ).

              APPEND ls_resp_item TO et_resp_list.
            ENDIF.

            IF is_transporte-cedula IS INITIAL.
              ls_resp_item = VALUE #(
                    code = |E-{ lv_status_code }|
                    title = |Cédula esta vacio|
                    detail = |El Numero de cédula no puede estar vacío| ).

              APPEND ls_resp_item TO et_resp_list.
            ENDIF.

        ENDCASE.

      WHEN 'S'. " Salida del Transporte GC

        lv_date = |{ is_transporte-hora_salida_planta+0(4) }{ is_transporte-hora_salida_planta+5(2) }{ is_transporte-hora_salida_planta+8(2) }|.
        lv_hours = |{ is_transporte-hora_salida_planta+11(2) }{ is_transporte-hora_salida_planta+14(2) }{ is_transporte-hora_salida_planta+17(2) }|.

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
               detail = |la fecha de salida { is_transporte-hora_salida_planta+0(10) } no es valida| ).

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
                  detail = |La hora de salida { is_transporte-hora_salida_planta+11(8) } no es valida| ).

          APPEND ls_resp_item TO et_resp_list.
        ENDIF.

        CASE ls_type_transp-tdocumento.
          WHEN 'RXP'.
            es_stage = VALUE #(
               tdocumento = ls_type_transp-tdocumento
               tknum = is_transporte-numguia
               sttrg = '7'
               date_stage = lv_date
               time_stage = lv_hours ).
        ENDCASE.

      WHEN 'EE'. "Entrada Transporte GD

        lv_date = |{ is_transporte-hora_entrada_planta+0(4) }{ is_transporte-hora_entrada_planta+5(2) }{ is_transporte-hora_entrada_planta+8(2) }|.
        lv_hours = |{ is_transporte-hora_entrada_planta+11(2) }{ is_transporte-hora_entrada_planta+14(2) }{ is_transporte-hora_entrada_planta+17(2) }|.

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
               detail = |la fecha de entrada a Planta { is_transporte-hora_entrada_planta+0(10) } no es valida| ).

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
                  detail = |La hora de entrada a Planta { is_transporte-hora_entrada_planta+11(8) } no es valida| ).

          APPEND ls_resp_item TO et_resp_list.
        ENDIF.

        IF is_transporte-empresa IS INITIAL.
          ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |La empresa está vacía|
              detail = |La empresa de transporte está vacío| ).

          APPEND ls_resp_item TO et_resp_list.
        ENDIF.

        IF is_transporte-placa IS INITIAL.
          ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |Placa del vehiculo está vacía|
              detail = |La placa del vehiculo está vacío| ).

          APPEND ls_resp_item TO et_resp_list.
        ENDIF.

        IF is_transporte-marca IS INITIAL.
          ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |Marca del vehiculo esta vacia|
              detail = |La marca del vehiculo est vacio| ).

          APPEND ls_resp_item TO et_resp_list.
        ENDIF.

        IF is_transporte-numero_pase IS INITIAL.
          ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |Numero del pase esta vacio|
              detail = |Numero del pase esta vacio| ).

          APPEND ls_resp_item TO et_resp_list.
        ENDIF.

        IF is_transporte-cedula IS INITIAL.
          ls_resp_item = VALUE #(
                code = |E-{ lv_status_code }|
                title = |Cédula esta vacio|
                detail = |El Numero de cédula del conductor no puede estar vacío| ).

          APPEND ls_resp_item TO et_resp_list.
        ENDIF.
    ENDCASE.
*    et_resp = lt_resp_list.

    CHECK et_resp_list[] IS INITIAL.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD commit_work.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

  METHOD roolback_work.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
*      IMPORTING
*        return =     " Return Messages
      .
  ENDMETHOD.

  METHOD save_cond_guia.
    DATA:
      ls_thead TYPE thead,
      ls_text  TYPE tline,
      lv_name  TYPE tdobname.

    DATA(driver_raw) = mt_drivers[ cedula = mv_cedula ].

*    SELECT SINGLE nombre, apellido
*    FROM zsd_tb_drivers
*    INTO @DATA(ls_conductor)
*    WHERE cedula = @is_transporte-cedula.

    lv_name = is_transporte-numguia.

    " Nombre del Conductor
    ls_text = VALUE #(
         tdformat = |*|
         tdline   = |{ driver_raw-nombre } { driver_raw-apellido }| ).

    ls_thead = VALUE #(
        mandt = sy-mandt
        tdspras = lc_spras
        tdid = 'Z001'
        tdobject = lc_object
        tdname = lv_name ).

    save_texto(
      EXPORTING
        is_thead     = ls_thead
        is_tline     = ls_text
        iv_mensaje   = |Conductor|
      CHANGING
        rt_resp_list = rt_resp_list ).

    "Cédula del conductor
    ls_text = VALUE #(
         tdformat = |*|
         tdline   = |{ is_transporte-nacionalidad }{ driver_raw-cedula }| ).

    ls_thead = VALUE #(
        mandt = sy-mandt
        tdspras = lc_spras
        tdid = 'Z008'
        tdobject = lc_object
        tdname = lv_name ).

    save_texto(
      EXPORTING
        is_thead     = ls_thead
        is_tline     = ls_text
        iv_mensaje   = |Cédula|
      CHANGING
        rt_resp_list = rt_resp_list ).

    "Teléfono del conductor
    ls_text = VALUE #(
     tdformat = |*|
     tdline   = |{ driver_raw-telefono }| ).

    ls_thead = VALUE #(
        mandt = sy-mandt
        tdspras = lc_spras
        tdid = 'Z002'
        tdobject = lc_object
        tdname = lv_name ).

    save_texto(
      EXPORTING
        is_thead     = ls_thead
        is_tline     = ls_text
        iv_mensaje   = |Teléfono|
      CHANGING
        rt_resp_list = rt_resp_list ).

    "PASE DE VIGILANCIA
    ls_text = VALUE #(
     tdformat = |*|
     tdline   = |{ is_transporte-numero_pase }| ).

    ls_thead = VALUE #(
        mandt = sy-mandt
        tdspras = lc_spras
        tdid = 'Z003'
        tdobject = lc_object
        tdname = lv_name ).

    save_texto(
      EXPORTING
        is_thead     = ls_thead
        is_tline     = ls_text
        iv_mensaje   = |Pase de Vigilancia|
      CHANGING
        rt_resp_list = rt_resp_list ).

    "PLACA del Vehículo
    ls_text = VALUE #(
     tdformat = |*|
     tdline   = |{ is_transporte-placa }| ).

    ls_thead = VALUE #(
        mandt = sy-mandt
        tdspras = lc_spras
        tdid = 'Z004'
        tdobject = lc_object
        tdname = lv_name ).

    save_texto(
      EXPORTING
        is_thead     = ls_thead
        is_tline     = ls_text
        iv_mensaje   = |Placa del Vehículo|
      CHANGING
        rt_resp_list = rt_resp_list ).

    "Correo de la unidad de transporte
    ls_text = VALUE #(
     tdformat = |*|
     tdline   = |{ driver_raw-email }| ).

    ls_thead = VALUE #(
        mandt = sy-mandt
        tdspras = lc_spras
        tdid = 'Z007'
        tdobject = lc_object
        tdname = lv_name ).

    save_texto(
      EXPORTING
        is_thead     = ls_thead
        is_tline     = ls_text
        iv_mensaje   = |Correo|
      CHANGING
        rt_resp_list = rt_resp_list ).

  ENDMETHOD.

  METHOD save_texto.

    DATA:
*      ls_thead TYPE thead,
      lt_lines TYPE TABLE OF tline.

    CLEAR lt_lines.

    APPEND is_tline TO lt_lines.

    TRY.
        CALL FUNCTION 'SAVE_TEXT'
          EXPORTING
            client          = sy-mandt    " Mandante
            header          = is_thead   " Cabecera del texto que se ha de graba
            savemode_direct = abap_true    " Indicador: Grabar texto inmediatamente
          TABLES
            lines           = lt_lines   " Líneas del texto que se ha de grabar
          EXCEPTIONS
            id              = 1
            language        = 2
            name            = 3
            object          = 4
            OTHERS          = 5.

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSE.
          commit_work( ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |Error al grabar en la guía|
              detail = lx_error->get_text( ) ).

        APPEND ls_resp_item TO rt_resp_list.
        RETURN.

    ENDTRY.
    lv_status_code = 200.

    ls_resp_item = VALUE #(
                  code = |OK-{ lv_status_code }|
                  title = |Texto Guardado|
                  detail = |Se guardo: { iv_mensaje }| ).

    APPEND ls_resp_item TO rt_resp_list.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD load_data.
    mv_cedula = iv_cedula.

    IF NOT line_exists( mt_drivers[ cedula = me->mv_cedula ] ).
      SELECT nacionalidad, cedula, nombre, apellido, telefono, email
       FROM zsd_tb_drivers
      WHERE cedula EQ @me->mv_cedula
      APPENDING TABLE @mt_drivers.

      IF sy-subrc NE 0.
        es_resp_item = VALUE #(
        code = |E-401|
        title = |Cédula no existe|
        detail = |El numero de cédula { mv_cedula } no existe| ).

        RETURN.
      ENDIF.

    ENDIF.

    rv_return = abap_true.
  ENDMETHOD.

  METHOD valid_pesada.
    CONSTANTS lc_char TYPE c LENGTH 1 VALUE ':'.

    DATA:
      lv_date  TYPE sy-datum,
      lv_hours TYPE sy-uzeit,
      lv_guion TYPE c LENGTH 1 VALUE '-',
      lv_dpun  TYPE c LENGTH 1 VALUE ':'.

    DATA lt_det_romana TYPE STANDARD TABLE OF zsd_tb_romanap.

*    lt_det_romana[] = is_transporte-datos_pesaje[].

    CLEAR lt_resp_list.

    lv_status_code = 422.

    LOOP AT is_transporte-datos_pesaje INTO DATA(ls_pesada).

      ls_pesada-diferencia = abs( ls_pesada-diferencia ).

      es_pesaje = VALUE #(
          tknum = is_transporte-numguia
          peso_tara = ls_pesada-peso_tara
          peso_bruto = ls_pesada-peso_bruto
          peso_neto = ls_pesada-peso_neto
          diferencia = ls_pesada-diferencia ).

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = es_pesaje-peso_tara    " Any ABAP field
        IMPORTING
          output = es_pesaje-peso_tara.       " External INPUT display, C field

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = es_pesaje-peso_bruto    " Any ABAP field
        IMPORTING
          output = es_pesaje-peso_bruto.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = es_pesaje-peso_neto    " Any ABAP field
        IMPORTING
          output = es_pesaje-peso_neto.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = es_pesaje-diferencia    " Any ABAP field
        IMPORTING
          output = es_pesaje-diferencia.

* Tara
      lv_date = |{ ls_pesada-hora_tara+0(4) }{ ls_pesada-hora_tara+5(2) }{ ls_pesada-hora_tara+8(2) }|.

      IF lv_date CS lv_guion.
        ls_resp_item = VALUE #(
             code = |E-{ lv_status_code }|
             title = |Formato de la fecha no valido (YYYY-MM-DD)|
             detail = |la fecha peso tara { ls_pesada-hora_tara+0(10) } no es valida| ).

        APPEND ls_resp_item TO et_resp_list.
      ELSE.
        CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
          EXPORTING
            date                      = lv_date
          EXCEPTIONS
            plausibility_check_failed = 1
            OTHERS                    = 2.

        IF sy-subrc NE 0.
          ls_resp_item = VALUE #(
               code = |E-{ lv_status_code }|
               title = |Formato de la fecha no valido  (YYYY-MM-DD)|
               detail = |la fecha peso tara { ls_pesada-hora_tara+0(10) } no es valida| ).

          APPEND ls_resp_item TO et_resp_list.
        ELSE.
          es_pesaje-fecha_tara = lv_date.
        ENDIF.
      ENDIF.

*      IF lv_hours CS lv_dpun.
      IF ls_pesada-hora_tara+11(2) CS lv_dpun OR
         ls_pesada-hora_tara+14(2) CS lv_dpun OR
         ls_pesada-hora_tara+17(2) CS lv_dpun.

        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Formato de la hora no valido|
            detail = |La hora peso tara { ls_pesada-hora_tara+11 } no es valida| ).

        APPEND ls_resp_item TO et_resp_list.
      ELSE.
        lv_hours = |{ ls_pesada-hora_tara+11(2) }{ ls_pesada-hora_tara+14(2) }{ ls_pesada-hora_tara+17(2) }|.

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
                  detail = |La hora peso tara { ls_pesada-hora_tara+11(8) } no es valida| ).

          APPEND ls_resp_item TO et_resp_list.
        ELSE.
          es_pesaje-hora_tara = lv_hours.
        ENDIF.
      ENDIF.

* Bruto
      lv_date = |{ ls_pesada-hora_bruto+0(4) }{ ls_pesada-hora_bruto+5(2) }{ ls_pesada-hora_bruto+8(2) }|.

      IF lv_date CS lv_guion.
        ls_resp_item = VALUE #(
             code = |E-{ lv_status_code }|
             title = |Formato de la fecha no valido|
             detail = |la fecha peso bruto { ls_pesada-hora_bruto+0(10) } no es valida| ).

        APPEND ls_resp_item TO et_resp_list.
      ELSE.

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
               detail = |la fecha peso bruto { ls_pesada-hora_bruto+0(10) } no es valida| ).

          APPEND ls_resp_item TO et_resp_list.
        ELSE.
          es_pesaje-fecha_bruto = lv_date.
        ENDIF.
      ENDIF.

*      IF lv_hours CS lv_dpun.
      IF ls_pesada-hora_bruto+11(2) CS lv_dpun OR
         ls_pesada-hora_bruto+14(2) CS lv_dpun OR
         ls_pesada-hora_bruto+17(2) CS lv_dpun.

        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Formato de la hora no valido|
            detail = |La hora peso bruto { ls_pesada-hora_bruto+11 } no es valida| ).

        APPEND ls_resp_item TO et_resp_list.
      ELSE.
        lv_hours = |{ ls_pesada-hora_bruto+11(2) }{ ls_pesada-hora_bruto+14(2) }{ ls_pesada-hora_bruto+17(2) }|.

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
                  detail = |La hora peso bruto { ls_pesada-hora_bruto+11(8) } no es valida| ).

          APPEND ls_resp_item TO et_resp_list.
        ELSE.
          es_pesaje-hora_bruto = lv_hours.
        ENDIF.
      ENDIF.

    ENDLOOP.

    CHECK et_resp_list[] IS INITIAL.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD save_pesaje.
    DATA:
*          ls_gck    TYPE zsd_tb_gck,
      lv_date   TYPE sy-datum,
      lv_hours  TYPE sy-uzeit,
      iv_posnr  TYPE posnr VALUE 10,
      lv_result TYPE c LENGTH 1,
      ls_romk   TYPE zsd_tb_romanak,
      ls_romp   TYPE zsd_tb_romanap,
      lt_romk   TYPE STANDARD TABLE OF zsd_tb_romanak,
      lt_romp   TYPE STANDARD TABLE OF zsd_tb_romanap.

    ev_code = 421.
    ev_reason = |Error en los datos|.

*    CHECK rv_return EQ abap_true.

    lv_date = |{ is_romana-hora_entrada_planta+0(4) }{ is_romana-hora_entrada_planta+5(2) }{ is_romana-hora_entrada_planta+8(2) }|.
    lv_hours = |{ is_romana-hora_entrada_planta+11(2) }{ is_romana-hora_entrada_planta+14(2) }{ is_romana-hora_entrada_planta+17(2) }|.

    SELECT COUNT(*)
      INTO @DATA(lv_cont)
      FROM zsd_tb_romanap
      WHERE tknum EQ @is_romana-numguia.

    IF sy-subrc NE 0.
      iv_posnr = 10.
    ELSE.
      lv_cont = lv_cont + 1.
      iv_posnr = lv_cont * 10.

      UPDATE zsd_tb_romanap
         SET peso_valido = abap_false
       WHERE tknum EQ is_romana-numguia.
    ENDIF.

    ls_romp = VALUE
        #( tknum       = is_romana-numguia
           posnr       = iv_posnr
           peso_tara   = is_pesaje-peso_tara
           fecha_tara  = is_pesaje-fecha_tara
           hora_tara   = is_pesaje-hora_tara
           peso_bruto  = is_pesaje-peso_bruto
           fecha_bruto = is_pesaje-fecha_bruto
           hora_bruto  = is_pesaje-hora_bruto
           peso_neto   = is_pesaje-peso_neto
           diferencia  = is_pesaje-diferencia
           peso_valido = abap_true ).

*    ls_romk = VALUE
*#( tplst         = mv_tplst
*tknum         = is_romana-numguia
*nacionalidad  = is_romana-nacionalidad
*cedula        = is_romana-cedula
*empresa       = is_romana-empresa
*placa         = is_romana-placa
*marca         = is_romana-marca
*modelo        = is_romana-modelo
*numero_pase   = is_romana-numero_pase
*motivo        = is_romana-motivo
*fecha_entrada = lv_date
*hora_entrada  = lv_hours ).

    INSERT zsd_tb_romanap FROM ls_romp.

    IF sy-subrc = 0.
      lv_status_code = 200.
      lv_reason = 'OK'.
      ls_resp_item = VALUE #(
            code = |{ lv_reason }-{ lv_status_code }|
            title = |Guardado con éxito|
            detail = |Se guardado con éxito el peso del transporte :{ ls_romk-tknum } | ).

      APPEND ls_resp_item TO et_resp_list.
    ELSE.
      lv_status_code = 422.
      lv_reason = 'Registro no guardado'.
      ls_resp_item = VALUE #(
            code = |e-{ lv_status_code }|
            title = |Error al guardar|
            detail = |no se pudo guardar el peso del transporte:{ ls_romk-tknum }| ).

      APPEND ls_resp_item TO et_resp_list.
    ENDIF.

    ev_code = lv_status_code.
    ev_reason = lv_reason.
*    ls_romk = VALUE #( tknum )
*    et_resp_list = lt_resp_list.

    IF lv_status_code EQ 200.
      commit_work( ).
      rv_return = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD save_pesaje_guia.
    DATA:
      ls_thead TYPE thead,
      ls_text  TYPE tline,
      lv_name  TYPE tdobname.

    lv_name = is_transporte-numguia.

    "Pesaje de la Romana
    ls_text = VALUE #(
         tdformat = |*|
         tdline   = |{ is_pesaje-peso_neto } KG.| ).

    ls_thead = VALUE #(
        mandt = sy-mandt
        tdspras = lc_spras
        tdid = 'Z006'
        tdobject = lc_object
        tdname = lv_name ).

    save_texto(
      EXPORTING
        is_thead     = ls_thead
        is_tline     = ls_text
        iv_mensaje   = |Peso de la Romana|
      CHANGING
        rt_resp_list = rt_resp_list ).

  ENDMETHOD.

  METHOD send_salida_transp.
    DATA(lo_innovo) = NEW zcl_sd_innovo(
        iv_tknum   = is_romak-tknum
        iv_json    = ''
        is_amb     = ms_innovo
*      iv_mostrar = iv_mostrar
    ).

    rv_return = lo_innovo->exit_despacho(
        EXPORTING
          is_romana     = is_romak
        CHANGING
          et_resp_list = et_resp_list ).

*    IF lo_innovo->exit_despacho(
*          CHANGING et_resp_list = et_resp_list ) EQ abap_false.
    IF rv_return EQ abap_false.
      lv_status_code = 422.
      lv_reason = 'No procesado'.
      ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Error al procesar|
            detail = |no se pudo guardar la salida del transporte:{ is_romak-tknum }| ).

      APPEND ls_resp_item TO et_resp_list.
    ENDIF.

  ENDMETHOD.

*  METHOD upd_guia.
**    UPDATE zsd_tb_gck
**       SET usr_exit = sy-uname
**           fec_exit = is_romak-fecha_salida
**           hora_exit = is_romak-hora_salida
**     WHERE
***     tdocumento = 'GC' AND
**           tknum = is_romak-tknum AND
**            env_desp = 'S'.
*
**    IF sy-subrc EQ 0.
*
**      lv_status_code = 200.
**      lv_reason = 'Guardado'.
**
**      ls_resp_item = VALUE #(
**            code = |OK-{ lv_status_code }|
**            title = |Datos actualizados|
**            detail = |Se guardo la salida del transporte: { is_romak-tknum }| ).
**
**      APPEND ls_resp_item TO et_resp_list.
*
*    UPDATE vttk
*       SET sttbg = 'X'
*           datbg = is_romak-fecha_salida
*           uatbg = is_romak-hora_salida
*     WHERE tknum = is_romak-tknum.
*
*    IF sy-subrc EQ 0.
*      ls_resp_item = VALUE #(
*            code = |OK-{ lv_status_code }|
*            title = |Datos actualizados|
*            detail = |Status actualizado del transporte: { is_romak-tknum }| ).
*
*      APPEND ls_resp_item TO et_resp_list.
*    ELSE.
*      lv_status_code = 422.
*      lv_reason = 'No guardado'.
*
*      ls_resp_item = VALUE #(
*            code = |E-{ lv_status_code }|
*            title = |Datos No actualizados|
*            detail = |No se guardo el status del transporte: { is_romak-tknum }| ).
*
*      APPEND ls_resp_item TO et_resp_list.
*      RETURN.
*    ENDIF.
**    ELSE.
**      lv_status_code = 422.
**      lv_reason = 'Mo guardado'.
**
**      ls_resp_item = VALUE #(
**            code = |E-{ lv_status_code }|
**            title = |Datos No actualizados|
**            detail = |No se guardo la salida del transporte: { is_romak-tknum }| ).
**
**      APPEND ls_resp_item TO et_resp_list.
**      RETURN.
**    ENDIF.
*
*    commit_work( ).
*
*    rv_return = abap_true.
*  ENDMETHOD.

ENDCLASS.
