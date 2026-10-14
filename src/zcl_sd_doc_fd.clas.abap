*  FECHA DE CREACION: 11.05.2026
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : CLASS
*  ORDEN          : DR3K982084
*  Solicitud      : REQ-1354
*&---------------------------------------------------------------------*
*   Descripción
*   Creacion de End Point para INNOVO de Guia Carga, Orden de Entrega
*   y Factura
*&---------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
* Fecha       Caso   User    Orden       Descripción
*
*&--------------------------------------------------------------------*
CLASS zcl_sd_doc_fd DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun.

    CONSTANTS:
        gc_sistema TYPE string VALUE 'QR3'.

    TYPES:
      tyr_tknum TYPE RANGE OF vttk-tknum,

      BEGIN OF ty_guia,
        tplst  TYPE tplst,
        tknum  TYPE tknum,
        dig_sl TYPE abap_bool,
      END OF ty_guia,

      tt_guia TYPE ty_guia,

      BEGIN OF ty_desp,
        tplst  TYPE tplst,
        tknum  TYPE tknum, "tyr_tknum,
        dig_sl TYPE abap_bool,
      END OF ty_desp,

      BEGIN OF ty_json,
        id   TYPE i,
        json TYPE string,
      END OF ty_json,

      BEGIN OF ty_json_gen,
        gd  TYPE string,
        fac TYPE string,
        oe  TYPE string,
      END OF ty_json_gen,
*
      tt_json TYPE STANDARD TABLE OF ty_json,

      BEGIN OF ty_ambiente,
        sysid   TYPE sy-sysid,
        url     TYPE zurl,
        api_key TYPE string,
      END OF ty_ambiente.

    DATA:
      mv_proccess TYPE char3 READ-ONLY,
      ms_guia     TYPE ty_guia READ-ONLY,
      ms_desp     TYPE ty_desp  READ-ONLY,
      mv_json     TYPE string READ-ONLY,
      mv_view     TYPE abap_bool,
      ms_amb      TYPE ty_ambiente READ-ONLY,
      ms_dat_gc   TYPE zsd_st_datos_gc READ-ONLY.
*      mv_tplst TYPE tplst READ-ONLY,
*      v_tknum  TYPE tknum READ-ONLY.

    METHODS:
      init "constructor
        IMPORTING
          is_guia      TYPE tt_guia OPTIONAL
          is_desp      TYPE ty_desp OPTIONAL
          iv_proccess  TYPE char3 OPTIONAL
          is_dat_gc    TYPE zsd_st_datos_gc OPTIONAL
          iv_mostrar   TYPE abap_bool OPTIONAL
*                  iv_tknum TYPE tknum
        EXPORTING
          ev_json_gc   TYPE string
          ev_json_oe   TYPE string
          ev_json_fa   TYPE string
          ev_json_desp TYPE string
          !et_json     TYPE tt_json
        RAISING
          cx_abap_invalid_value.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.

CLASS zcl_sd_doc_fd IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
*    DATA ls_guia TYPE tt_guia.

    DATA(ls_guia) = VALUE ty_guia( tplst = 1200
                                   tknum = 137114 ).

    me->ms_guia = VALUE #( tplst = ls_guia-tplst
                           tknum = ls_guia-tknum ).

    TRY.
*        DATA(lo_docdig) = NEW lcl_doc_fd( is_guia = ms_guia
*                                          iv_orden = 'LR' ).
        DATA(lo_docdig) = NEW lcl_doc_fd( is_guia = ms_guia
                                          iv_orden = 'RXP'
                                          is_dat_gc = ms_dat_gc
                                          iv_mostrar = abap_true ).
      CATCH cx_abap_invalid_value. "cx_ INTO cx.
    ENDTRY.

    mv_json = lo_docdig->mv_json.

    " Mostrar resultado
    out->write( |Centro: { ms_guia-tplst }, transporte: { ms_guia-tknum }.| ).
*
*    out->write( | Centro { ms_guia-tplst } Transporte { ms_guia-tknum }| ).
  ENDMETHOD.

  METHOD init. "constructor.
    DATA ls_guia TYPE ty_guia.

*    me->ms_guia = VALUE #( tplst = 1200
*                           tknum = 137114 ).

    me->ms_dat_gc = is_dat_gc.
    me->mv_proccess = iv_proccess.

    CASE me->mv_proccess.
      WHEN 'RXP'.
        me->ms_desp = VALUE #( tplst = is_desp-tplst
                               tknum = is_desp-tknum
                               dig_sl = is_desp-dig_sl ).

        ls_guia = VALUE #( tplst = is_desp-tplst
                           tknum = is_desp-tknum ).
      WHEN OTHERS.
        me->ms_guia = VALUE #( tplst = is_guia-tplst
                               tknum = is_guia-tknum ).

        ls_guia = VALUE #( tplst = is_guia-tplst
                           tknum = is_guia-tknum ).

    ENDCASE.
*    me->ms_guia = VALUE #( tplst = is_guia-tplst
*                          tknum = is_guia-tknum
*                          dig_sl = is_guia-dig_sl ).

    me->mv_view = iv_mostrar.

    DATA(lo_docdig) = NEW lcl_doc_fd( is_guia = ls_guia
                                      iv_orden = mv_proccess
                                      is_dat_gc = ms_dat_gc ).

    IF NOT is_guia IS INITIAL.
      TRY.
*          DATA(lo_docdig) = NEW lcl_doc_fd(
*                              is_guia = ms_guia
*                              iv_orden = iv_orden ).
          lo_docdig->init(
            EXPORTING
              is_guia    = ms_guia
              iv_proccess   = mv_proccess
              iv_mostrar = iv_mostrar  ).
*  CATCH cx_abap_invalid_value.    "
        CATCH cx_abap_invalid_value. "cx_ INTO cx.
          EXIT.
      ENDTRY.
    ELSEIF  NOT is_desp IS INITIAL.
      TRY.
          lo_docdig->init_rxp(
              EXPORTING
                is_guia     = ms_desp
                iv_proccess = mv_proccess
                iv_mostrar  = iv_mostrar  ).
*          lo_docdig = NEW lcl_doc_fd(
*                              is_guia = ms_guia
*                              iv_orden = iv_orden ).
        CATCH cx_abap_invalid_value. "cx_ INTO cx.
          EXIT.
      ENDTRY.
    ELSE.
      EXIT.
    ENDIF.

    ev_json_gc = lo_docdig->mv_json.

    ev_json_fa = lo_docdig->mv_json_fac.

    ev_json_oe = lo_docdig->mv_json_oe.

    ev_json_desp = lo_docdig->mv_json_con.

*    et_json[] = lo_docdig->mt_json[].

    IF mv_view EQ abap_true.
      IF sy-uname EQ '700-009'.
        cl_demo_output=>display( ev_json_oe ).
        cl_demo_output=>display( ev_json_desp ).

        IF sy-sysid NE gc_sistema.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

    IF ev_json_desp IS NOT INITIAL.
      TRY.
*      ms_amb = lo_docdig->ms_amb
          DATA(lo_desp) = NEW zcl_sd_innovo(
              iv_tknum = ls_guia-tknum
              iv_json  = ev_json_desp
*              is_amb   = lo_docdig->ms_amb
              is_amb   = lo_docdig->ms_service
              iv_mostrar = mv_view ).

          lo_desp->send_despacho( ).
        CATCH cx_abap_invalid_value. "cx_ INTO cx.
      ENDTRY.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
