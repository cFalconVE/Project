@AbapCatalog.sqlViewName: 'ZV_ADRNR_ENT'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Dirección de entrega para OE'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zv_adrnr_entrega 
    with parameters
//        p_vbeln : vbeln
        p_parvw : parvw
    as select from vbpa as dc
    association[1] to tpart as _fun on  $projection.parvw = _fun.parvw
                                    and _fun.spras = 'S'
{
    key dc.vbeln,
    key _fun.parvw as parvw,
        dc.kunnr,
        dc.adrnr
}
where parvw = $parameters.p_parvw
