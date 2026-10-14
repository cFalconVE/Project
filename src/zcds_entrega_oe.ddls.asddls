@AbapCatalog.sqlViewName: 'ZCDS_ENTREGA_OE'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista de entregas para las ordenes de entregas OE'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zview_entrega_oe 
    with parameters
        p_tplst : tplst
//        p_tknum : tknum
    as 
    select from vttk as vk
      
// Posiciones del Transporte
    association[1] to zview_enr_po_oe as _vp on $projection.nrotransporte = _vp.nroTransporte

// Organización
    association[1] to zview_org_vtas as ov on $projection.orgVta = ov.orgVtas
    
//Transporte
//    association [1] to lfa1 as cl on $projection.tdlnr = cl.lifnr
//    association[1] to zview_transporte as tr on $projection.tdlnr = tr.lifnr
    
//Clase de Transporte
    association [1] to t173t as ct on $projection.vsart = ct.vsart
                                   and ct.spras = 'S' 
{
    key vk.tplst as orgVta,
    key vk.tknum as nrotransporte,
        cast( '' as abap.char( 10 ) ) as nroTranOri,
        vk.tdlnr,
        vk.frkrl as indGasTrans,
        vk.vsart,
//    key vp( p_tknum: $parameters.p_tknum ).nroEntrega,
//        vp( p_tknum: $parameters.p_tknum ).nroPedido,
        _vp.nroEntrega,
        _vp.isImprimir,
        _vp.lfart,
        _vp.nroPedido,
        _vp.waerk,        
        _vp.nroPosiciones,
//        vp.,
        ov.rif,
        ov.razonSocial,
        ov.dir1,
        ov.dir2,
        ov.dir3,
        ov.pais,
        ov.ciudad,
        ov.paisCiudad,
        ov.telefono,
//        ov.correOrg  as emailRecep,
        cast( '' as abap.char( 50 ) ) as correoDestino,
        cast( '' as abap.char( 50 ) ) as correo,
//        cast( '' as abap.char( 20 ) ) as tipTranps,
        cast( '' as abap.char( 40 ) ) as transporte,
//        ct.bezei as tipTrans,
        cast( '' as abap.char( 10 ) ) as nroPlaca,
        _vp.kunnr,
        _vp.kunag,
        cast( '' as abap.char( 160 ) ) as diReceptor,
//        tr.dirTrans1,
//        tr.dirTrans2,
//        tr.cityTran2,
//        tr.paisTrans,
////        tr.correoTrans,
        cast( '' as abap.char( 80 ) ) as observaciones,
        cast( 0 as abap.int1 ) as pag,
        cast( '' as abap.char( 1 ) ) as status,
// Vistas y tablas asociadas        
        _vp
        
} where vk.tplst = $parameters.p_tplst
//    and ( _vp.lfart = 'ZECN' or _vp.lfart = 'NL' )
//    and vk.tknum = $parameters.p_tknum
