CLASS lcl_romana_serv DEFINITION.

  PUBLIC SECTION.
    DATA:
      mv_lista TYPE abap_bool READ-ONLY.

    METHODS:
      constructor
        IMPORTING iv_lista TYPE abap_bool,

      set_lista_cond
        RETURNING VALUE(rv_return) TYPE abap_bool,

      get_transporte
        IMPORTING
          iv_rif           TYPE lifnr OPTIONAL
          iv_type          TYPE c
        EXPORTING
          et_transp        TYPE zsd_tt_transporte
        RETURNING
          VALUE(tv_return) TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
        " Calidad
*        cv_url TYPE string VALUE 'http://172.17.3.248:5000/api/lista-conductores'.
    "Productivo
    cv_url TYPE string VALUE 'http://172.17.3.248:5000/api/lista-conductores'.

    DATA:
      lo_http_client TYPE REF TO if_http_client,
      lv_response    TYPE string,
      lv_status      TYPE i.

    " Estructura para mapear el JSON
    TYPES: BEGIN OF ty_post,
             userid TYPE i,
             id     TYPE i,
             title  TYPE string,
             body   TYPE string,
           END OF ty_post.

    DATA: ls_post TYPE ty_post.

ENDCLASS.

CLASS lcl_romana_serv IMPLEMENTATION.

  METHOD constructor.
    mv_lista = iv_lista.

  ENDMETHOD.

  METHOD set_lista_cond.
    IF mv_lista EQ abap_true.

    ENDIF.

  ENDMETHOD.

  METHOD get_transporte.
    DATA:
      lv_langu      TYPE langu VALUE 'S',
      lt_transporte TYPE zsd_tt_transporte,
      ls_transp     TYPE zsd_st_transporte,
      ls_types      TYPE zsd_st_types.


    CASE iv_type.
      WHEN 'T'.
        IF iv_rif IS INITIAL.
          SELECT DISTINCT *
            FROM zview_emp_transp
            INTO TABLE @DATA(lt_transp).
        ELSE.
          SELECT DISTINCT *
            FROM zview_emp_transp
            INTO TABLE @lt_transp
            WHERE carrier_code EQ @iv_rif.
        ENDIF.

        IF sy-subrc NE 0.
          WRITE: 'Cargar primero los conductores'.
          MESSAGE 'Error: Cargar primero los conductores' TYPE 'E'.
        ENDIF.

        CHECK sy-subrc EQ 0.

        LOOP AT lt_transp INTO DATA(ls_item).

          IF ls_item-carrier_code NE 'J5008869181'.

            ls_transp = VALUE #(
                  code = ls_item-carrier_code
                  name = ls_item-name1
                  identity_type = ls_item-carrier_code(1)
                  tax_id = ls_item-carrier_code+1
                  contact_name = ls_item-remark
                  contact_phone = ls_item-tel_number
                  contact_email = ls_item-smtp_addr
                  active = |true| ).

            ls_types = VALUE #( types = 'transporter' ).

            APPEND ls_types TO ls_transp-types[].

            APPEND ls_transp TO lt_transporte.

          ENDIF.

        ENDLOOP.

      WHEN 'D' OR 'P'.
        IF iv_rif IS INITIAL.
          SELECT *
            FROM zview_com_transp
           WHERE type_serv EQ @iv_type
            INTO TABLE @DATA(lt_opelog).
        ELSE.
          SELECT *
            FROM zview_com_transp
            WHERE lifnr EQ @iv_rif AND
                  type_serv EQ @iv_type
            INTO TABLE @lt_opelog.
        ENDIF.

        LOOP AT lt_opelog INTO DATA(ls_opelog).

          ls_transp = VALUE #(
                code = ls_opelog-lifnr
                name = ls_opelog-name1
                identity_type = ls_opelog-lifnr(1)
                tax_id = ls_opelog-lifnr+1
                contact_name = ls_opelog-remark
                contact_phone = ls_opelog-tel_number
                contact_email = ls_opelog-smtp_addr
                active = |true| ).

          ls_types = VALUE #( types = ls_opelog-types ).

          APPEND ls_types TO ls_transp-types[].

          APPEND ls_transp TO lt_transporte.

        ENDLOOP.

    ENDCASE.

    et_transp[] = lt_transporte[].

  ENDMETHOD.

ENDCLASS.
