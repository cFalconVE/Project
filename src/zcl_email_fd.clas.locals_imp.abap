CLASS lcl_email DEFINITION.

  PUBLIC SECTION.

    CONSTANTS: gc_sistema TYPE string VALUE 'PR3'.

    DATA: mv_asunto TYPE so_obj_des READ-ONLY,
          ms_oe_log TYPE zsd_tb_oe_log READ-ONLY.

    TYPES:
      BEGIN OF st_list_email,
        bukrs      TYPE bukrs,
        tdocumento TYPE ztdocumento,
        addr6      TYPE ad_smtpadr,
        activo     TYPE actsg,
      END OF st_list_email,

      tt_list_email TYPE STANDARD TABLE OF st_list_email
            WITH NON-UNIQUE KEY bukrs tdocumento addr6.

    CLASS-DATA lt_list_email TYPE tt_list_email.

    METHODS:
      constructor
        IMPORTING
                  i_asunto TYPE so_obj_des
                  i_oe_log TYPE zsd_tb_oe_log
        RAISING   cx_abap_invalid_value,
*                cx_sy_itab_line_not_found.
*        EXCEPTIONS.

      send_msg_mail.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS gc_status_e(1) TYPE c VALUE 'E'.

    TYPES: tt_receiver  TYPE STANDARD TABLE OF adr6-smtp_addr,
           tt_lines     TYPE STANDARD TABLE OF tline WITH DEFAULT KEY,
           ty_html_text TYPE TABLE OF htmlline.

    METHODS:
      get_list_email
        IMPORTING
                  iv_tplst             TYPE tplst
                  iv_tdoc              TYPE ztdocumento
        RETURNING VALUE(rt_list_email) TYPE tt_list_email,

      save_list_email
        IMPORTING
          iv_tplst TYPE tplst
          iv_tdoc  TYPE ztdocumento,

      commit_work,

      find_email_address
        IMPORTING
                  is_oe_log TYPE zsd_tb_oe_log
        EXPORTING !et_addr  TYPE tt_receiver,

      read_body_mail
        EXPORTING es_header TYPE thead
                  et_lines  TYPE tt_lines,

      get_det_body
        IMPORTING
                  is_oe_log     TYPE zsd_tb_oe_log
        CHANGING  et_body_email TYPE ty_html_text.

ENDCLASS.

CLASS lcl_email IMPLEMENTATION.

  METHOD constructor.

    me->mv_asunto = i_asunto.
    me->ms_oe_log = i_oe_log.

    TRY.
        DATA(email_raw) = lt_list_email[ bukrs = ms_oe_log-sociedad
                                         tdocumento = ms_oe_log-tdocumento
                                         activo = abap_true ].

      CATCH cx_sy_itab_line_not_found.
        lt_list_email = get_list_email( iv_tplst = ms_oe_log-sociedad
                                        iv_tdoc  = ms_oe_log-tdocumento ).
    ENDTRY.

    IF NOT line_exists( lt_list_email[ bukrs = ms_oe_log-sociedad
                                       tdocumento = ms_oe_log-tdocumento ] ).
      save_list_email( iv_tplst = ms_oe_log-sociedad
                     iv_tdoc  = ms_oe_log-tdocumento ).
      lt_list_email = get_list_email( iv_tplst = ms_oe_log-sociedad
                                      iv_tdoc  = ms_oe_log-tdocumento ).
    ENDIF.

  ENDMETHOD.

  METHOD get_list_email.

    TRY.
        SELECT *
          FROM zsd_tb_send_mail
         WHERE bukrs EQ @iv_tplst
           AND tdocumento EQ @iv_tdoc
           AND activo EQ @abap_true
          INTO CORRESPONDING FIELDS OF TABLE @rt_list_email.

      CATCH cx_abap_invalid_value.
        CLEAR rt_list_email.
    ENDTRY.

  ENDMETHOD.

  METHOD save_list_email.
    DATA lt_user_ti TYPE TABLE OF zsd_tb_send_mail.

    lt_user_ti = VALUE #( ( bukrs = iv_tplst
                            tdocumento = iv_tdoc
                            addr6 = 'carlos_falcon@corimon.com'
                            activo = abap_true
                            ernam = sy-uname
                            erdat = sy-datum
                            erzet = sy-uzeit )
                          ( bukrs = iv_tplst
                            tdocumento = iv_tdoc
                            addr6 = 'pedro_marquez@corimon.com'
                            activo = abap_true
                            ernam = sy-uname
                            erdat = sy-datum
                            erzet = sy-uzeit )
                          ( bukrs = iv_tplst
                            tdocumento = iv_tdoc
                            addr6 = 'william_leon@corimon.com'
                            activo = abap_true
                            ernam = sy-uname
                            erdat = sy-datum
                            erzet = sy-uzeit ) ).

    MODIFY zsd_tb_send_mail FROM TABLE lt_user_ti.

    me->commit_work( ).

  ENDMETHOD.

  METHOD commit_work.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

  METHOD send_msg_mail.
    DATA: xxml_out TYPE xstring.

    DATA: len    TYPE sood-objlen,
          length TYPE  i.

    DATA: binary_content TYPE solix_tab.

    DATA: text  TYPE bcsy_text,
          text1 TYPE bcsy_text.

    DATA: xtext TYPE STANDARD TABLE OF solix .

    DATA: lo_send_request TYPE REF TO cl_bcs,
          lo_document     TYPE REF TO cl_document_bcs,
          sender          TYPE REF TO if_sender_bcs,
          recipient       TYPE REF TO if_recipient_bcs.

    DATA: sent_to_all TYPE os_boolean.

    DATA: atta_sub     TYPE sood-objdes,
          app_type(50).

    DATA: bcs_message TYPE string.

    DATA: lv_asunto   TYPE so_obj_des,
          lv_cuerpo   TYPE bcsy_text,
          lt_receiver TYPE TABLE OF adr6-smtp_addr.

    DATA: lv_sender TYPE adr6-smtp_addr.

    CONSTANTS: lc_htm    TYPE char03 VALUE 'HTM',
               lc_id     TYPE tdid VALUE 'ST',
               lc_object TYPE tdobject VALUE 'TEXT'.

    DATA lv_att_title TYPE so_obj_des.

    DATA: lt_lines  TYPE TABLE OF tline,
          ls_header TYPE thead.

    me->find_email_address(
      EXPORTING
        is_oe_log = ms_oe_log
      IMPORTING
        et_addr   = lt_receiver ).

    me->read_body_mail(
      IMPORTING
        es_header   = ls_header
        et_lines    = lt_lines ).

* Convert Text template to HTML - email body
    DATA: lt_html_text  TYPE TABLE OF htmlline,
          lt_body_email TYPE soli_tab.

    DATA lv_thead TYPE thead .

    CALL FUNCTION 'CONVERT_ITF_TO_HTML'
      EXPORTING
        i_header       = ls_header
        i_title        = 'Falla de comunicación Servicio SL'
      TABLES
        t_itf_text     = lt_lines
        t_html_text    = lt_html_text
      EXCEPTIONS
        syntax_check   = 1
        replace        = 2
        illegal_header = 3
        OTHERS         = 4.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    me->get_det_body(
      EXPORTING
        is_oe_log     = ms_oe_log
      CHANGING
        et_body_email = lt_html_text ).

    lt_body_email[] = lt_html_text[].

    TRY.
        CLEAR lo_send_request.

        lo_send_request = cl_bcs=>create_persistent( ).

* Add sender to the request
        lo_send_request->set_sender( i_sender = cl_sapuser_bcs=>create( sy-uname ) ).

* Add recipients to the request
        CLEAR lv_sender.

        LOOP AT lt_receiver INTO lv_sender.
          lo_send_request->add_recipient(
            i_recipient = cl_cam_address_bcs=>create_internet_address( lv_sender )
            i_express   = abap_true ).
        ENDLOOP.

        CLEAR lo_document.

        lo_document = cl_document_bcs=>create_document( i_type = lc_htm
                                                        i_subject = mv_asunto
                                                        i_text = lt_body_email ).

        CALL METHOD lo_send_request->set_document( lo_document ).

        CALL METHOD lo_send_request->set_status_attributes
          EXPORTING
            i_requested_status = gc_status_e
            i_status_mail      = gc_status_e.

        CALL METHOD lo_send_request->set_send_immediately( 'X' ).
* ---------- send document ---------------------------------------
        CALL METHOD lo_send_request->send(
          EXPORTING
            i_with_error_screen = 'X'
          RECEIVING
            result              = sent_to_all ).

        COMMIT WORK.

      CATCH cx_bcs INTO DATA(lo_bcs_exception).
        bcs_message = lo_bcs_exception->get_text( ).
        WRITE : |Type: { lo_bcs_exception->error_type } / Message { lo_bcs_exception->get_text( ) }|.
        MESSAGE i208(00) WITH 'Error envio: Revise direcciones de correo asociadas'.
        EXIT.

    ENDTRY.

  ENDMETHOD.

  METHOD find_email_address.

    LOOP AT lt_list_email INTO DATA(ls_list).
      APPEND ls_list-addr6 TO et_addr.
    ENDLOOP.

  ENDMETHOD.

  METHOD read_body_mail.
    CONSTANTS: lc_htm    TYPE char03 VALUE 'HTM',
               lc_id     TYPE tdid VALUE 'ST',
               lc_name   TYPE tdobname VALUE 'ZST_EMAIL_FD_ERROR',
               lc_object TYPE tdobject VALUE 'TEXT'.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        client                  = sy-mandt  " Mandante
        id                      = lc_id     " ID del texto a leer
        language                = sy-langu  " Idioma del texto a leer
        name                    = lc_name   " Nombre del texto a leer
        object                  = lc_object " Objeto del texto a leer
      IMPORTING
        header                  = es_header " Cabecera del texto leído
      TABLES
        lines                   = et_lines  " Líneas del texto leído
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

*********Replacing variables in template***********
    CALL FUNCTION 'INIT_TEXTSYMBOL'.

    DATA(lv_count) = lines( et_lines ).

    CALL FUNCTION 'REPLACE_TEXTSYMBOL'
      EXPORTING
        endline   = lv_count
        startline = 1
      TABLES
        lines     = et_lines.
***************************************************

  ENDMETHOD.

  METHOD get_det_body.
    DATA: lv_text     TYPE string,
          lt_lines    TYPE TABLE OF tline,
          lt_line     TYPE tline,
          lv_hora     TYPE tims,
          lv_hora_out TYPE zhoraemision,
          lv_am_pm(2) TYPE c,
          lv_erdat    TYPE erdat.

    CLEAR: lv_text.

    DESCRIBE TABLE et_body_email LINES DATA(lv_line).
    DELETE et_body_email INDEX lv_line.

    DESCRIBE TABLE et_body_email LINES lv_line.
    DELETE et_body_email INDEX lv_line.

    APPEND '<table>' TO et_body_email.

    APPEND '<tr>' TO et_body_email.

    APPEND '<td width=100px><b>Filial</b></td>' TO et_body_email.
    APPEND '<td><b>Tip. Doc.</b></td>' TO et_body_email.
    APPEND '<td aling=center><b>Documento</b></td>'  TO et_body_email.
    APPEND '<td aling=center><b>Página</b></td>'  TO et_body_email.
    APPEND '<td aling=center><b>Mensaje</b></td>'  TO et_body_email.
    APPEND '<td aling=center><b>Fecha</b></td>'  TO et_body_email.
    APPEND '<td aling=center><b>Hora</b></td>'  TO et_body_email.

    APPEND '</tr>' TO et_body_email.

    APPEND '<tr>' TO et_body_email.

    lv_erdat = is_oe_log-erdat.

    WRITE sy-datum TO lv_erdat DD/MM/YYYY.

    lv_hora = is_oe_log-erzet.

    CALL FUNCTION 'HRVE_CONVERT_TIME'
      EXPORTING
        type_time       = 'A'
        input_time      = is_oe_log-erzet
        input_am_pm     = 'AM'
      IMPORTING
        output_time     = lv_hora
        output_am_pm    = lv_am_pm
      EXCEPTIONS
        parameter_error = 1.

    WRITE lv_hora TO lv_hora_out ENVIRONMENT TIME FORMAT.
*    WRITE lv_hora TO lv_hora hh:mm:ss.

*Filial
    CONCATENATE '<td aling=center>' is_oe_log-sociedad '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td aling=center>' is_oe_log-tdocumento '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td>' is_oe_log-ndocumento '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td>' is_oe_log-pagina '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td>' is_oe_log-mensaje '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td>' lv_erdat '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td align=right>' lv_hora_out '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    APPEND '</tr>' TO et_body_email.
    APPEND '</table>' TO et_body_email.
    APPEND '</body>' TO et_body_email.
    APPEND '</html>' TO et_body_email.

  ENDMETHOD.

ENDCLASS.
