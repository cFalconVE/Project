CLASS zcl_document_digital DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_extension.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_document_digital IMPLEMENTATION.
  METHOD if_http_extension~handle_request.

    CONSTANTS: c_object_start TYPE c VALUE '{',
               c_object_end   TYPE c VALUE '}'.

    FIELD-SYMBOLS <fs_param> TYPE LINE OF tihttpnvp.

    DATA: lv_path_info      TYPE string,
          lv_request_method TYPE string,
          c_vbrk(4)         TYPE c      VALUE 'VBRK',
          lv_response_data  TYPE string.

    DATA: ti_msku   TYPE TABLE OF msku,
          wa_msku   TYPE          msku,
          v_paletas TYPE  i.

    DATA: w_fechai TYPE datum,
          lv_fecha TYPE datum.

    DATA: w_fechaf TYPE datum.

    DATA: wdias TYPE i.

    DATA: kwert_b       TYPE konv-kbetr,
          kumza         TYPE konv-kumza,
          kbetr2        TYPE konv-kbetr,
          v_p_base      TYPE  zed_importe,
          v_dscto       TYPE  zed_importe,
          wentrega      TYPE string,
          v_factura_ref TYPE  vbeln,
          recargo       TYPE konv-kbetr.

    DATA: marca           TYPE  /sapdii/wty_refkt,
          marca_text      TYPE  tvm1t-bezei,
          etiqueta_marca  TYPE  string,
          v_etiqueta      TYPE string,
          v_cunet         TYPE  i,
          v_cajas         TYPE  i,
          v_paila         TYPE  i,
          v_otro          TYPE  zsd_cantidad,
          v_pieza         TYPE  char8,
          v_barri         TYPE  i,
          coleccion_marca TYPE  string.

    DATA: ls_cab TYPE zsd_st_json.
    DATA: ls_det TYPE zsd_detalles.
    DATA: ls_fin   TYPE zsd_financia,
          wa_adrc  TYPE adrc,
          wa_kna1  TYPE kna1,
          wa_tvzbt TYPE tvzbt,
          wa_t052u TYPE t052u,
          wa_t052  TYPE t052,
          wa_t006b TYPE t006b,
          wa_tvgrt TYPE tvgrt,
          wa_likp  TYPE likp,
          wa_konv  TYPE konv.

    FIELD-SYMBOLS: <fs_bapi> TYPE zsd_st_json,
                   <fs_line> TYPE tline.

    DATA: itline     TYPE TABLE OF tline, " WITH HEADER LINE,
          w_observa1 TYPE  char80,
          w_observa2 TYPE  char80.
    DATA: iname TYPE tdobname.

    DATA:
      lv_text        TYPE string,
      lv_text1       TYPE string,
      lv_socied      TYPE bukrs,
      lv_mseh3       TYPE mseh3,
      wproce(5),
      wbanners       TYPE zbanners,
      ti_banner      TYPE TABLE OF zsd_tb_banners,
      wa_banner      LIKE LINE OF ti_banner,
      ti_report      TYPE TABLE OF zsd_st_json,
      ti_fadet       TYPE TABLE OF vbrp,
      ti_bkpf        TYPE TABLE OF bkpf,
      ti_t052s       TYPE TABLE OF t052s,
      wa_t052s       LIKE LINE OF ti_t052s,
      wa_fadet       LIKE LINE OF ti_fadet,
      wa_bkpf        LIKE LINE OF ti_bkpf,
      ti_facturasimp TYPE TABLE OF vbrk,
      wa_ti_fac      LIKE LINE OF ti_facturasimp,
      w_vbrk         LIKE LINE OF ti_facturasimp.


    DATA: it_inputparams TYPE tihttpnvp,
          it_inputparam1 TYPE tihttpnvp,
          ls_inputparams TYPE LINE OF tihttpnvp.



    lv_path_info = server->request->get_header_field( name = '~path_info' ).

    lv_request_method = server->request->get_header_field( name = '~request_method' ).

    "Only GET is allowed

    IF lv_request_method NE 'GET'.

      CALL METHOD server->response->set_header_field( name = 'Allow' value = 'GET' ).

      CALL METHOD server->response->set_status( code = '405' reason = 'Method not allowed' ).

      EXIT.

    ENDIF.
    CALL METHOD server->request->get_header_fields
      CHANGING
        fields = it_inputparam1.


    CALL METHOD server->request->get_form_fields
      CHANGING
        fields = it_inputparams.

    UNASSIGN <fs_param>.

    LOOP AT it_inputparams ASSIGNING <fs_param>.

      TRANSLATE <fs_param>-name TO UPPER CASE.

    ENDLOOP.

    READ TABLE it_inputparams INTO ls_inputparams WITH KEY name = 'SOCIEDAD'.

    lv_socied = ls_inputparams-value.
    CLEAR ls_inputparams.

    READ TABLE it_inputparams INTO ls_inputparams WITH KEY name = 'FECHA'.

    lv_fecha = ls_inputparams-value.
    CLEAR ls_inputparams.

    IF lv_request_method EQ 'GET' AND lv_socied NE space.

      zcl_enviarfactdigital=>enviar_doc_facncnd(
        EXPORTING
          sociedad    =   lv_socied  " Sociedad
          fecha       =   lv_fecha " Fecha de factura para el índice de factura e impresión
*         FACTURA     =     " Número de documento comercial
        RECEIVING
          result_json = lv_text
      ).

      CALL METHOD server->response->set_cdata( data = lv_text ).

    ENDIF.
  ENDMETHOD.

ENDCLASS.
