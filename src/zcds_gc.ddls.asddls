@AbapCatalog.sqlViewName: 'ZCDS_GC'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista de Guias de Carga generadas'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zview_gc 
    with parameters
        p_tplst : tplst
    as select from zsd_tb_gck as gck
//    Detalle de las guías de carga generadas
    association[0..*] to zsd_tb_gcp as gcp on $projection.nroTransp_k = gcp.tknum_c
//  Asociar el tipo de transporte
    association[1..1] to vttk as vk on $projection.nroTransp_k = vk.tknum   
                                   and $projection.tplst = vk.tplst   
{
    key gck.tplst,
    key gck.tknum as nroTransp_k,
        gck.estado as estado_k,
        gck.erdat as fechaEnvio,
        gck.env_desp,
        gcp.tknum as nroTransp,
        vk.vsart,
        vk.gesztd,
        gcp.pagina,
        gcp.estado as estado_p        
} where gck.tplst = $parameters.p_tplst
