*&---------------------------------------------------------------------*
*&  Include  zsdr_oe_digital_t01
*&---------------------------------------------------------------------*
*&  Fecha:      10.09.2025
*&  Autor:      700-009 : CFALCON
*&  ServiDesk:  REQ-C1049 Caso: 55601
*&  Transporte: DR3K980133
*&  Titulo:     Reporte Ordenes de entrega FD
*----------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
*&   Fecha       Caso   User    Orden      Descripción
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
TABLES:
  zsd_likp_oe,
  zsd_tb_json_stat,
  likp.

TYPES: BEGIN OF tt_likp_oe,
         tplst    TYPE zsd_likp_oe-tplst,
         femision TYPE zsd_likp_oe-erdat,
         likp_oe  TYPE i,
       END OF tt_likp_oe.

TYPES: BEGIN OF tt_likp_h,
         tplst      TYPE zsd_likp_oe-tplst,
         erdat      TYPE zsd_likp_oe-erdat,
         vbeln      TYPE zsd_likp_oe-vbeln,
         vbeln_oe   TYPE zsd_tb_json_stat-vbeln,
         estado     TYPE zsd_likp_oe-estado,
         tdocumento TYPE zsd_likp_oe-tdocumento,
         status     TYPE icon_d,
         pag        TYPE zsd_likp_oe-pag,
       END OF tt_likp_h.

TYPES: BEGIN OF tt_likp_d,
         paginas  TYPE i,
         vbeln    TYPE zsd_tb_json_stat-vbeln,
         vbeln_oe TYPE zsd_likp_oe-vbeln_oe,
         ncontrol TYPE zsd_tb_json_stat-ncontrol,
         pagina   TYPE zsd_likp_oe-pag,
         estado   TYPE zsd_likp_oe-estado,
         status   TYPE icon_d,
*         fechareci TYPE zsd_tb_json_stat-fechareci,
         femision TYPE zsd_likp_oe-femision,
         hemision TYPE zsd_likp_oe-hemision,
         url      TYPE zsd_tb_json_stat-url,
       END OF tt_likp_d.

DATA: gv_ucomm TYPE sy-ucomm.

DATA: gt_likp_oe_h TYPE TABLE OF tt_likp_h,
      gt_likp_oe_d TYPE TABLE OF tt_likp_d,
      gt_likp_oe   TYPE TABLE OF tt_likp_oe.

DATA: gt_tree_output TYPE TABLE OF tt_likp_d.

DATA: go_container TYPE REF TO cl_gui_docking_container,
      go_split     TYPE REF TO cl_gui_splitter_container,
      go_top       TYPE REF TO cl_gui_container,
      go_bottom    TYPE REF TO cl_gui_container,
      go_tree      TYPE REF TO cl_gui_alv_tree.

DATA: gs_tree_header TYPE  treev_hhdr,
      go_document    TYPE REF TO cl_dd_document,
      gt_fieldcat    TYPE lvc_t_fcat,
      l_last_key     TYPE lvc_nkey,
      l_top_key      TYPE lvc_nkey,
      l_node_key     TYPE lvc_nkey,
      l_node2_key    TYPE lvc_nkey,
      l_node_line    TYPE lvc_nkey.
