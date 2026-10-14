*&---------------------------------------------------------------------*
*&  Include           ZSDR_GUIAS_CARGA_DITITAL_T01
*&---------------------------------------------------------------------*
TABLES: zsd_tb_gck, zsd_tb_gcp.

TYPES: BEGIN OF tt_doc_detail,
         tknum            TYPE vttk-tknum,
         vbeln            TYPE lips-vbeln,
         vbeln_oe         TYPE zsd_likp_oe-vbeln_oe,
         vbeln_fac        TYPE vbrk-vbeln,
         fec_procesado    TYPE aedat,
         hora_procesado   TYPE aezet,
         fec_procesado_fc TYPE aedat,
         hora_procesado_fc TYPE aezet,
       END OF tt_doc_detail.

TYPES: BEGIN OF tt_guias,
         tplst TYPE zsd_tb_gck-tplst,
         erdat TYPE zsd_tb_gck-erdat,
         guias TYPE i,
       END OF tt_guias.

TYPES: BEGIN OF tt_guias_h,
         tplst  TYPE zsd_tb_gck-tplst,
         erdat  TYPE zsd_tb_gck-erdat,
         tknum  TYPE zsd_tb_gck-tknum,
         estado TYPE zsd_tb_gck-estado,
         status TYPE icon_d,
         pagina TYPE zsd_tb_gcp-pagina,
         flujo  TYPE char10,
       END OF tt_guias_h.

TYPES: BEGIN OF tt_guias_d,
         paginas   TYPE i,
         tknum_c   TYPE zsd_tb_gck-tknum,
         tknum     TYPE zsd_tb_gck-tknum,
         pagina    TYPE zsd_tb_gcp-pagina,
         estado    TYPE zsd_tb_gcp-estado,
         status    TYPE icon_d,
         aedat     TYPE zsd_tb_gcp-aedat,
         aezet     TYPE zsd_tb_gcp-aezet,
         env_desp  TYPE  icon_d,
         fec_desp  TYPE  aedat,
         hora_desp TYPE	aezet,
         fec_exit  TYPE  aedat,
         hora_exit TYPE	aezet,
         fec_fin   TYPE	aedat,
         hora_fin  TYPE  aezet,
         vbeln_oe  type ZSD_LIKP_OE-VBELN_OE,
         flujo     TYPE char10,
         url       TYPE zsd_tb_gcp-url,
       END OF tt_guias_d.

DATA: gv_ucomm TYPE sy-ucomm.
DATA: gt_guias_h TYPE TABLE OF tt_guias_h,
      gt_guias_d TYPE TABLE OF tt_guias_d,
      gt_guias   TYPE TABLE OF tt_guias.
DATA:
          gt_tree_output TYPE TABLE OF tt_guias_d.

DATA: o_container TYPE REF TO cl_gui_docking_container,
      o_split     TYPE REF TO cl_gui_splitter_container,
      o_top       TYPE REF TO cl_gui_container,
      o_bottom    TYPE REF TO cl_gui_container,

      o_tree      TYPE REF TO cl_gui_alv_tree.

DATA: gs_tree_header TYPE  treev_hhdr,
      o_document     TYPE REF TO cl_dd_document,
      gt_fieldcat    TYPE lvc_t_fcat,
      l_last_key     TYPE lvc_nkey,
      l_top_key      TYPE lvc_nkey,
      l_node_key     TYPE lvc_nkey,
      l_node2_key    TYPE lvc_nkey,
      l_node3_key    TYPE lvc_nkey,
      l_node4_key    TYPE lvc_nkey,
      l_node5_key    TYPE lvc_nkey,
      l_node_line    TYPE lvc_nkey.

DATA: gt_doc_detail TYPE TABLE OF tt_doc_detail.

SELECTION-SCREEN: BEGIN OF BLOCK b01 WITH FRAME TITLE text-001.
SELECT-OPTIONS:   so_tplst  FOR zsd_tb_gck-tplst OBLIGATORY NO-EXTENSION NO INTERVALS,
                  so_tknum  FOR zsd_tb_gck-tknum,
                  so_erdat  FOR zsd_tb_gck-erdat OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK b01.

AT SELECTION-SCREEN.
  PERFORM validate_init_entry.


INITIALIZATION.
  PERFORM init_data.
