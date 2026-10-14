CLASS zcl_sd_serv_digital DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    DATA ms_service TYPE zsd_st_serv_url READ-ONLY.

    METHODS:
      init
        IMPORTING
          is_service TYPE zsd_st_serv_url,

      create
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      update
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      get_services
        CHANGING
          es_service       TYPE zsd_st_serv_url
        RETURNING
          VALUE(rv_return) TYPE abap_bool.

  PROTECTED  SECTION.
  PRIVATE SECTION.

ENDCLASS.

CLASS zcl_sd_serv_digital IMPLEMENTATION.

  METHOD init.
    ms_service = is_service.

    get_services(
      CHANGING
        es_service = ms_service ).
  ENDMETHOD.

  METHOD create.

    IF ms_service IS NOT INITIAL.
      ms_service-ernam = sy-uname.
      ms_service-erdat = sy-datum.
      ms_service-erzet = sy-uzeit.

      MODIFY zsd_tb_serv_url FROM ms_service.
    ENDIF.

    CHECK NOT ms_service IS INITIAL.
    CHECK sy-subrc EQ 0.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD update.

    CHECK NOT ms_service IS INITIAL.

    IF ms_service IS NOT INITIAL.
      ms_service-aenam = sy-uname.
      ms_service-aedat = sy-datum.
      ms_service-aezet = sy-uzeit.

      UPDATE zsd_tb_serv_url
      SET url = ms_service-url
          api_key = ms_service-api_key
          servicio = ms_service-servicio
          ip = ms_service-ip
          activo = ms_service-activo
          aenam = sy-uname
          aedat = sy-datum
          aezet = sy-uzeit
       WHERE bukrs EQ ms_service-bukrs AND
             sysid EQ ms_service-sysid AND
             servicio EQ ms_service-servicio.
    ENDIF.

    CHECK sy-subrc EQ 0.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD get_services.

    IF es_service IS NOT INITIAL.

      SELECT SINGLE url, api_key, servicio, ip, activo
        FROM zsd_tb_serv_url
        INTO @DATA(ls_service)
        WHERE bukrs EQ @es_service-bukrs AND
              sysid EQ @es_service-sysid AND
              servicio EQ @es_service-servicio AND
              activo EQ @abap_true. "157.230.61.45
    ENDIF.

    CHECK sy-subrc EQ 0.

*    es_service-bukrs = ls_service-bukrs.
*    es_service-sysid = ls_service-sysid.
    es_service-url = ls_service-url.
    es_service-api_key = ls_service-api_key.
    es_service-servicio = ls_service-servicio.
    es_service-ip = ls_service-ip.
    es_service-activo = ls_service-activo.

    rv_return = abap_true.

  ENDMETHOD.

ENDCLASS.
