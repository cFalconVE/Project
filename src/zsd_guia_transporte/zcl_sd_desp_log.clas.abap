CLASS zcl_sd_desp_log DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_json,
        tplst   TYPE tplst,
        proceso TYPE char3,
        json    TYPE string,
      END OF ty_json,

      tt_json TYPE STANDARD TABLE OF ty_json,

      BEGIN OF ty_response_item,
        code   TYPE string,
        title  TYPE string,
        detail TYPE string,
      END OF ty_response_item,

      tt_response_list TYPE STANDARD TABLE OF ty_response_item WITH EMPTY KEY,

      BEGIN OF ty_response,
        status       TYPE i,
        reason       TYPE string,
        tdocumento   TYPE ztdocumento,
        nrodocumento TYPE vbeln,
        fecha        TYPE datum,
        hora         TYPE sy-uzeit,
        message      TYPE tt_response_list,
      END OF ty_response,

      tt_response TYPE ty_response,

      BEGIN OF ty_resp_rom,
        status  TYPE i,
        reason  TYPE string,
        tdocu   TYPE char3,
        numguia TYPE i,
        fecha   TYPE datum,
        hora    TYPE sy-uzeit,
        message TYPE tt_response_list,
      END OF ty_resp_rom.

    DATA:
        mv_json TYPE ty_json READ-ONLY.

    METHODS:
      constructor
        IMPORTING
          is_json TYPE ty_json,

      save_json
        IMPORTING
          is_json TYPE ty_json,

      save_tracking
        IMPORTING
          iv_tplst    TYPE tplst
          is_resp_ino TYPE ty_response OPTIONAL
          is_resp_rom TYPE ty_resp_rom OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS:
      commit_work,

      roolback_work.

ENDCLASS.

CLASS zcl_sd_desp_log IMPLEMENTATION.
  METHOD constructor.
    mv_json = is_json.

    save_json( mv_json ).

  ENDMETHOD.

  METHOD save_json.
    DATA ls_json TYPE zsd_tb_desp_json.

    SELECT COUNT(*)
     INTO @DATA(lv_posnr)
     FROM zsd_tb_desp_json.

    IF lv_posnr = 0.
      lv_posnr = 1.
    ELSE.
      lv_posnr = lv_posnr + 1.
    ENDIF.

    ls_json = VALUE #(
        tplst = is_json-tplst
        proceso = is_json-proceso
        posnr = lv_posnr
        json = is_json-json
        ernam = sy-uname
        erdat = sy-datum
        erzet = sy-uzeit ).

    INSERT zsd_tb_desp_json FROM ls_json.

    IF sy-subrc EQ 0.
      commit_work( ).
    ELSE.
      roolback_work( ).
    ENDIF.

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

  METHOD save_tracking.
    DATA:
      ls_logk  TYPE zsd_tb_des_logk,
      ls_logp  TYPE zsd_tb_des_logp,
      lv_posnr TYPE posnr.

    SELECT MAX( posdocnr )
      INTO @DATA(lv_max)
      FROM zsd_tb_des_logk.

    IF sy-subrc EQ 0 OR
       lv_max GT 0.
      lv_max = lv_max.
    ELSE.
      lv_max = 1.
    ENDIF.

    IF is_resp_ino IS INITIAL.

      ls_logk = VALUE #(
          status = is_resp_rom-status
          reason = is_resp_rom-reason
          tplst = iv_tplst
          tdocumento = is_resp_rom-tdocu
          nrodocumento = is_resp_rom-numguia
          posdocnr = lv_max
          ernam = sy-uname
          erdat = sy-datum
          erzet = sy-uzeit ).

      INSERT zsd_tb_des_logk FROM ls_logk.

      IF sy-subrc EQ 0.
        lv_posnr = 1.

        LOOP AT is_resp_rom-message INTO DATA(ls_det).
          ls_logp = VALUE #(
              tplst = iv_tplst
              tdocumento = ls_logk-tdocumento
              nrodocumento = ls_logk-nrodocumento
              posdocnr = lv_max
              posnr = lv_posnr
              code = ls_det-code
              title = ls_det-title
              detail = ls_det-detail
              ernam = ls_logk-ernam
              erdat = ls_logk-erdat
              erzet = ls_logk-erzet ).

          lv_posnr = lv_posnr + 1.

          INSERT zsd_tb_des_logp FROM ls_logp.
        ENDLOOP.
      ENDIF.
    ELSE.
      ls_logk = VALUE #(
        status = is_resp_ino-status
        reason = is_resp_ino-reason
        tplst = iv_tplst
        tdocumento = is_resp_ino-tdocumento
        nrodocumento = is_resp_ino-nrodocumento
        posdocnr = lv_max
        ernam = sy-uname
        erdat = sy-datum
        erzet = sy-uzeit ).

      INSERT zsd_tb_des_logk FROM ls_logk.

      IF sy-subrc EQ 0.
        lv_posnr = 1.
        LOOP AT is_resp_ino-message INTO ls_det.
          ls_logp = VALUE #(
              tplst = iv_tplst
              tdocumento = ls_logk-tdocumento
              nrodocumento = ls_logk-nrodocumento
              posdocnr = lv_max
              posnr = lv_posnr
              code = ls_det-code
              title = ls_det-title
              detail = ls_det-detail
              ernam = ls_logk-ernam
              erdat = ls_logk-erdat
              erzet = ls_logk-erzet ).
          lv_posnr = lv_posnr + 1.

          INSERT zsd_tb_des_logp FROM ls_logp.
        ENDLOOP.
      ENDIF.

    ENDIF.

    commit_work( ).

  ENDMETHOD.

ENDCLASS.
