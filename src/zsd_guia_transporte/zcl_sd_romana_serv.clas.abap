CLASS zcl_sd_romana_serv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_error_item,
        code   TYPE string,
        title  TYPE string,
        detail TYPE string,
      END OF ty_error_item,

      ty_error_list TYPE STANDARD TABLE OF ty_error_item WITH EMPTY KEY,

      BEGIN OF ty_error_response,
        status TYPE i,
        reason TYPE string,
        errors TYPE ty_error_list,
      END OF ty_error_response,

      tt_error_resp TYPE ty_error_response,

      BEGIN OF ty_response_item,
        code   TYPE string,
        title  TYPE string,
        detail TYPE string,
      END OF ty_response_item,

      tt_response_list TYPE STANDARD TABLE OF ty_response_item WITH EMPTY KEY,

      BEGIN OF ty_conductor,
        nacionalidad TYPE z_nacionalidad,
        cedula       TYPE zciconductor,
        email        TYPE zcorreo,
        exp_licencia TYPE dats,
        exp_salud    TYPE dats,
        nombre       TYPE zconductor,
        apellido     TYPE zconductor,
        rif          TYPE stcd1,
        telefono     TYPE telf1,
        transporte   TYPE zname1,
        activo       TYPE zsd_status_activo,
      END OF ty_conductor,

      tt_conductor TYPE STANDARD TABLE OF ty_conductor
       WITH NON-UNIQUE KEY cedula.

    DATA: lt_errors     TYPE ty_error_list,
          ls_error_item TYPE ty_error_item,
          ls_error_resp TYPE ty_error_response,
          lt_resp_list  TYPE tt_response_list,
          ls_resp_item  TYPE ty_response_item.

    TYPES:
        tt_driver_json TYPE STANDARD TABLE OF zsd_st_driver_json.

    DATA:
      mv_lista TYPE abap_bool READ-ONLY,
      mv_type  TYPE c1.

    CLASS-DATA:
      mt_transportes TYPE zsd_tt_transporte,
      mt_drivers     TYPE zsd_tt_driver_json.

    METHODS:
      constructor
        IMPORTING
          iv_lista  TYPE abap_bool OPTIONAL
          iv_transp TYPE abap_bool OPTIONAL
          iv_type   TYPE c1,

      init,

      list_transportes
        IMPORTING
          iv_rif           TYPE lifnr OPTIONAL
          iv_type          TYPE c1
        EXPORTING
          et_transp        TYPE zsd_tt_transporte
        RETURNING
          VALUE(tv_return) TYPE abap_bool,

      list_conductores
        EXPORTING
          et_drivers       TYPE zsd_tt_driver_json
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      save_conductores
        IMPORTING
          it_drivers       TYPE tt_conductor
          iv_init          TYPE abap_bool
        EXPORTING
          et_driver        TYPE zsd_tb_drivers
*        CHANGING
*          et_drivers       TYPE tt_conductor
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      valid_driver
        IMPORTING
          is_driver        TYPE ty_conductor
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool.

*      get_conductores
*        EXPORTING et_drivers TYPE

  PROTECTED SECTION.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_pesaje,
        peso_tara   TYPE i,
        fecha_tara  TYPE timestamp,
        peso_bruto  TYPE i,
        fecha_bruto TYPE timestamp,
        peso_neto   TYPE i,
        hora_neto   TYPE timestamp,
        dif_peso    TYPE i,
      END OF ty_pesaje,

      BEGIN OF ty_transporte,
        tknum       TYPE tknum,
        cedula      TYPE zciconductor,
        empresa     TYPE zname1,
        placa       TYPE zplvehiculo,
        marca       TYPE zzvehiculo,
        modelo      TYPE ztipovehiculo,
        pasenr      TYPE i,
        motivo      TYPE zmotivo,
        hora_salida TYPE timestamp,
        pesaje      TYPE ty_pesaje,
      END OF ty_transporte,

      tt_transporte TYPE ty_transporte.

    CLASS-DATA:
      mt_list_drivers TYPE tt_conductor.
*      mt_transportes  TYPE zsd_tt_transporte.

    METHODS:
      list_drivers
        EXPORTING es_drivers TYPE zsd_tt_driver_json,

      save_drivers
        IMPORTING
          it_drivers       TYPE tt_conductor
          iv_init          TYPE abap_bool
        EXPORTING
          et_driver        TYPE zsd_tb_drivers
*        CHANGING
*          et_drivers       TYPE tt_conductor
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      commit_work.

ENDCLASS.

CLASS zcl_sd_romana_serv IMPLEMENTATION.
  METHOD constructor.
    mv_lista = iv_lista.
    mv_type = iv_type.

    DATA(lo_serv) = NEW lcl_romana_serv( mv_lista ).

    IF iv_lista EQ abap_true.
      list_drivers(
        IMPORTING
          es_drivers = mt_drivers ).
    ENDIF.

    IF iv_transp EQ abap_true.
      lo_serv->get_transporte(
        EXPORTING
          iv_type   = iv_type
        IMPORTING
          et_transp = mt_transportes ).
    ENDIF.

  ENDMETHOD.

  METHOD init.

    list_drivers(
*    IMPORTING
*      es_drivers = es_drivers
    ).

  ENDMETHOD.

  METHOD list_drivers.
* El Http está configurado como rfc (SM59)
*    CONSTANTS:
**               lc_http_dest TYPE rfcdest VALUE 'FAC_DIGITAL',
*               lc_asunto    TYPE so_obj_des VALUE 'Error de comunicación con servicio SL'.

    DATA:
*      lv_url      TYPE string VALUE 'http://10.207.4.68:8000/sap/bc/fact_digital/zenviofactcrp?sap-client=510&SOCIEDAD=1200&FECHA=20240731',
*      lv_url      TYPE string VALUE  'http://172.17.3.248:5000/api/lista-conductores'.
" Productivo
*      lv_url      TYPE string VALUE  'http://172.17.3.248:8000/api/lista-conductores'.
*      lv_username TYPE string VALUE '700-009',
*      lv_password TYPE string VALUE 'Sep@4419*Q'.

     ls_serv_url TYPE zsd_st_serv_url.

    DATA(lo_serv_url) = NEW zcl_sd_serv_digital( ).

    ls_serv_url = VALUE #( sysid = sy-sysid
                  bukrs = '1200'
                  servicio = 'ROMANA' ).

    lo_serv_url->init( is_service = ls_serv_url ).

    lo_serv_url->get_services(
      CHANGING
        es_service = ls_serv_url ).

    DATA: lv_auth_header TYPE string,
          lv_response    TYPE string.

    DATA: lo_client      TYPE REF TO if_http_client,
          lo_response    TYPE REF TO if_http_response,
*          ls_json_sta    TYPE zsd_st_json_status,
*          st_json_sta    TYPE TABLE OF zsd_st_json_status WITH HEADER LINE,
*          ls_tb_json_sta TYPE zsd_tb_json_stat,
          lv_status_code TYPE i,
          lv_code        TYPE string,
          lv_json        TYPE string,
          lv_reason      TYPE string.
*          lv_tplst       TYPE tplst.

********************************************
* Crear el cliente HTTP
    CALL METHOD cl_http_client=>create_by_url
      EXPORTING
        url                = CONV string( ls_serv_url-url )
      IMPORTING
        client             = lo_client
      EXCEPTIONS
        argument_not_found = 1
        plugin_not_active  = 2
        internal_error     = 3
        OTHERS             = 4.

    IF sy-subrc <> 0 OR lo_client IS INITIAL.
      WRITE: 'Error al crear el cliente HTTP'.
      MESSAGE 'Error creando el cliente HTTP' TYPE 'E'.
      RAISE EXCEPTION TYPE cx_sy_no_handler.
*        EXPORTING
*          textid = cx_sy_no_handler=>textid.
      RETURN.
    ENDIF.

* Configurar la autenticación básica
*    lv_auth_header = cl_http_utility=>encode_base64( lc_username && ':' && lc_password ).

*    CONCATENATE 'Basic ' lv_auth_header INTO lv_auth_header SEPARATED BY ' '.

*    lo_http_client->request->set_header_field( name = 'Authorization' value = lv_auth_header ).
* Post
    TRY.
        " Establecer cabeceras obligatorias
        lo_client->request->set_header_field(
          name  = 'Content-Type'
          value = 'application/json;charset=utf-8' ).

        lo_client->request->set_header_field(
          name  = 'Accept'
          value = 'application/json' ).

** Enviar la solicitud HTTP GET
        lo_client->send(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            OTHERS                     = 4 ).

        IF sy-subrc <> 0.
          WRITE: 'Error al enviar la solicitud HTTP'.
          MESSAGE 'Error al enviar la solicitud HTTP' TYPE 'E'.

          ls_error_item = VALUE #(
             code = 'e0001'
             title = 'Error HTTP'
             detail = |Error al enviar la solicitud HTTP { sy-subrc }| ).

          ls_error_resp = VALUE #(
             status = sy-subrc
             reason = 'e001'
             errors = lt_errors ).
        ENDIF.

* Recibir la respuesta
        lo_client->receive(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            OTHERS                     = 4 ).

        CLEAR: lv_status_code.

        IF sy-subrc <> 0.
          MESSAGE 'Error al recibir la respuesta HTTP' TYPE 'E'.
* Ini 22.07.2025 55601 cfalcon DR3K979139 Tratar mensaje de error de Certificado SSL
          lo_response = lo_client->response.

          lv_status_code = lo_response->get_header_field('~status_code').
          lv_reason = lo_response->get_header_field( '~status_reason' ).

          IF lv_status_code EQ '500'.
*            mv_men_1 = 'Certificado ha expirado'.
*            mv_men_2 = 'Por favor comunicarse con TI'.
          ELSE.
*            mv_men_1 = 'Error al recibir respuesta del HTTP'.
*            CLEAR mv_men_2.
          ENDIF.
* Fin 22.07.2025 55601 cfalcon DR3K979139 Tratar mensaje de error de Certificado SSL

        ENDIF.

        lv_response = lo_client->response->get_cdata( ).

* Obtener el código de estado y la respuesta
        lo_client->response->get_status(
          IMPORTING
            code   = lv_status_code
            reason = lv_reason ).

        CASE lv_status_code.
          WHEN '200'.
*            save_drivers( it_drivers = mt_list_drivers
*                          iv_init    = abap_true ).

*            save_drivers(
*              EXPORTING
*                it_drivers = it_drivers
*                iv_init    = abap_true
*              CHANGING
*                et_drivers = mt_list_drivers ).

*            save_drivers(
*              EXPORTING
*                it_drivers = mt_list_drivers
*                iv_init    = abap_true
**              IMPORTING
**                et_driver  = et_driver
*                 ).
          WHEN '403'.
            ls_error_item = VALUE #(
              code = lv_status_code
              title = lv_reason
              detail = |Error en el Certificado SSL| ).

            ls_error_resp = VALUE #(
               status = sy-subrc
               reason = 'e001'
               errors = lt_errors ).
          WHEN '404'.
            ls_error_item = VALUE #(
               code = lv_status_code
               title = lv_reason
               detail = |Error en petición HTTP| ).

            ls_error_resp = VALUE #(
               status = sy-subrc
               reason = lv_reason
               errors = lt_errors ).

          WHEN '500'.
            ls_error_item = VALUE #(
               code = lv_status_code
               title = lv_reason
               detail = |No tienes permiso para acceder a este recurso| ).

            ls_error_resp = VALUE #(
               status = lv_status_code
               reason = lv_reason
               errors = lt_errors ).
          WHEN OTHERS.
            ls_error_item = VALUE #(
                code = lv_status_code
                title = lv_reason
                detail = |Error en perición Http| ).

            ls_error_resp = VALUE #(
                status = lv_status_code
                reason = lv_reason
                errors = lt_errors ).
        ENDCASE.

*        " Mostrar resultados
*        WRITE: / 'Status:', lv_status_code.
*        WRITE: / 'Respuesta:', lv_response.

*        lv_status_code = lo_response->get_header_field('~status_code').
*        lv_reason = lo_response->get_header_field( '~status_reason' ).

        cl_demo_output=>display( ls_error_item ).

        cl_demo_output=>display( lt_errors ).

      CATCH cx_http_ext_exception INTO DATA(lx_err).

        WRITE: / 'Excepción:', lx_err->get_text( ).
*        cs_log = ls_log.
*        ls_log-status = gc_status_e.
    ENDTRY.

    " Liberar recursos del cliente HTTP
    IF lo_client IS BOUND.
      lo_client->close( ).
    ENDIF.

**********************transforma respuesta del json en datos internos *****************
    /ui2/cl_json=>deserialize( EXPORTING
                                 json        = lv_response
                                 pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                               CHANGING
                                 data        = mt_list_drivers ).
***************************************************************************************
*No tienes permiso para acceder a este recurso
    CASE lv_status_code.
      WHEN '200'.
        save_drivers( it_drivers = mt_list_drivers
                      iv_init    = abap_true ).
    ENDCASE.

*    set_message( lt_message  ).

*    rv_return = abap_true.
  ENDMETHOD.

  METHOD save_drivers.
    DATA ls_driver TYPE zsd_tb_drivers.

    IF iv_init EQ abap_true.
      DELETE FROM zsd_tb_drivers.
    ENDIF.

    LOOP AT it_drivers INTO DATA(ls_item). " INTO DATA(ls_item).

      ls_driver = VALUE zsd_tb_drivers(
           carrier_code = ls_item-rif
           nacionalidad = ls_item-cedula+0(1)
           cedula = ls_item-cedula+1
           nombre = ls_item-nombre
           apellido = ls_item-apellido
           telefono = ls_item-telefono
           transporte = ls_item-transporte
           exp_licencia = ls_item-exp_licencia
           exp_salud = ls_item-exp_salud
           email = ls_item-email ).

      ls_driver-status = COND zsd_status_activo(
        WHEN ls_item-exp_licencia LE sy-datum OR
             ls_item-exp_salud LE sy-datum
          THEN 0
        ELSE 1 ).

      MODIFY zsd_tb_drivers FROM ls_driver.

    ENDLOOP.

    CHECK sy-subrc EQ 0.

    commit_work( ).

    et_driver = ls_driver.
    rv_return = abap_true.

*    MODIFY zhcmt_dotacion FROM TABLE gt_save_dotacion.
*
*    IF sy-subrc EQ 0.
*      go_userdot->commit_work(  ).
*      p_result = sy-subrc.
*    ELSE.
*      p_result = sy-subrc.
*    ENDIF.
*  ENDIF.

  ENDMETHOD.

  METHOD commit_work.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

  METHOD list_transportes.
    DATA(lo_serv) = NEW lcl_romana_serv( mv_lista ).

    lo_serv->get_transporte(
        EXPORTING
            iv_rif    = iv_rif
            iv_type   = iv_type
        IMPORTING
            et_transp = et_transp ).

*    lo_serv->get_transporte(
**  IMPORTING
**    et_transp = et_transp
**  RECEIVING
**    tv_return = tv_return
*    ).

  ENDMETHOD.

  METHOD list_conductores.
    TYPES:
      BEGIN OF st_cond,
        nombre   TYPE string,
        apellido TYPE string,
      END OF st_cond.

    DATA: lt_drivers TYPE zsd_tt_driver_json, " STANDARD TABLE OF zsd_st_driver_json,
          ls_cond    TYPE st_cond.

    SELECT *
    FROM zsd_tb_drivers
    INTO TABLE @DATA(lt_table).

    LOOP AT lt_table INTO DATA(ls_item).

      DATA(lv_status) = COND zsd_status(
        WHEN ls_item-status EQ 1
          THEN |active|
        ELSE |inactive| ).

      APPEND VALUE #(
        carrier_code = ls_item-carrier_code
        identity_number = |{ ls_item-nacionalidad }{ ls_item-cedula }|
        first_name = ls_item-nombre
        last_name = ls_item-apellido
        phone = ls_item-telefono
        email = ls_item-email
        status = lv_status )
      TO lt_drivers.
    ENDLOOP.

    et_drivers[] = lt_drivers[].
  ENDMETHOD.

  METHOD save_conductores.
    rv_return = me->save_drivers(
      EXPORTING
        it_drivers = it_drivers
        iv_init    = iv_init
      IMPORTING
        et_driver  = et_driver ).

  ENDMETHOD.

  METHOD valid_driver.
    DATA lv_error TYPE abap_bool.

    lv_error = abap_true.

    IF is_driver-cedula(1) CN 'EV'.
*      lv_status_code = 422.
*      lv_reason = 'Datos no válidos'.
      ls_resp_item = VALUE #(
            code = |E-422|
            title = |Nacionalidad Incorrecta|
            detail = |Falta nacionalidad en la Cédula:{ is_driver-cedula }| ).

      APPEND ls_resp_item TO et_resp_list.
      lv_error = abap_false.
    ENDIF.

    IF is_driver-apellido IS INITIAL OR
       is_driver-nombre IS INITIAL.
*      lv_status_code = 422.
*      lv_reason = 'Datos vacíos'.
      ls_resp_item = VALUE #(
            code = |E-422|
            title = |Campo Vacío|
            detail = |En la Cédula:{ is_driver-cedula }, el nombre o apellido no pueden estar vacío| ).

      APPEND ls_resp_item TO et_resp_list.
      lv_error = abap_false.
    ENDIF.

    IF is_driver-rif IS INITIAL.
*      lv_status_code = 422.
*      lv_reason = 'Datos vacíos'.
      ls_resp_item = VALUE #(
            code = |E-422|
            title = |Campo Vacío|
            detail = |En la Cédula:{ is_driver-cedula } el rif no puede estar vacío| ).

      APPEND ls_resp_item TO et_resp_list.
      lv_error = abap_false.
    ENDIF.

    IF is_driver-rif IS INITIAL.
*      lv_status_code = 422.
*      lv_reason = 'Datos vacíos'.
      ls_resp_item = VALUE #(
            code = |E-422|
            title = |Campo Vacío|
            detail = |En la Cédula:{ is_driver-cedula } el rif no puede estar vacío| ).

      APPEND ls_resp_item TO et_resp_list.
      lv_error = abap_false.
    ENDIF.

    IF is_driver-email IS INITIAL.
*      lv_status_code = 422.
*      lv_reason = 'Datos vacíos'.
      ls_resp_item = VALUE #(
            code = |E-422|
            title = |Campo Vacío|
            detail = |En la Cédula:{ is_driver-cedula } el correo no puede estar vacío| ).

      APPEND ls_resp_item TO et_resp_list.
      lv_error = abap_false.
    ENDIF.

    IF is_driver-telefono IS INITIAL.
*      lv_status_code = 422.
*      lv_reason = 'Datos vacíos'.
      ls_resp_item = VALUE #(
            code = |E-422|
            title = |Campo Vacío|
            detail = |En la Cédula:{ is_driver-cedula } el teléfono no puede estar vacío| ).

      APPEND ls_resp_item TO et_resp_list.
      lv_error = abap_false.
    ENDIF.

    rv_return = lv_error.

  ENDMETHOD.

ENDCLASS.
