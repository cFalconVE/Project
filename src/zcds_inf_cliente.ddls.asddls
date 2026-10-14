@AbapCatalog.sqlViewName: 'ZCDS_INF_CLIENTE'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista Infiormación del Cliente'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zview_inf_client 
//    as select from lfa1 as tr
    as select from kna1 as cl
// 
    association[1] to adrc as de on $projection.adrnr = de.addrnumber
//
//    association[1] to zview_cliente_correo as cc on $projection.lifnr = cc.kunnr
// Get email
    association[0..1] to adr6 as a6  on $projection.adrnr = a6.addrnumber
                                    and a6.flgdefault = 'X'
                                    and a6.persnumber = ' '
//
    association[0..1] to adrt as ar on $projection.adrnr = ar.addrnumber
//    and ar.consnumber = a6.consnumber                                   
//
    association[1] to t005t as t5 on  $projection.land1 = t5.land1
                                  and t5.spras = 'S'
{
    key cl.kunnr,
        cl.land1, 
        cl.adrnr,
        concat(de.name1, concat(' ', de.name2)) as nameClient,
        concat(de.str_suppl1, concat(' ', de.str_suppl2)) as dirClient1,
        concat(de.str_suppl3, concat(' ', de.post_code1)) as dirClient2,
        de.city2 as cityClient2,
        concat(t5.landx, concat(' - ', de.city1)) as paisClient,
        a6.smtp_addr as correoDestino,
        a6.date_from as dateform_a6,
        ar.comm_type,
        ar.remark,
        ar.consnumber,
        ar.date_from as dateform_ar
        
//    key tr.lifnr,
//        tr.land1, 
//        tr.adrnr,
//        concat(de.name1, concat(' ', de.name2)) as nameTrans,
//        concat(de.str_suppl1, concat(' ', de.str_suppl2)) as dirTrans1,
//        concat(de.str_suppl3, concat(' ', de.post_code1)) as dirTrans2,
//        de.city2 as cityTran2,
//        concat(t5.landx, concat(' - ', de.city1)) as paisTrans,
//        cc.smtp_addr as correoDestino
} where cl.land1 = 'VE'
//where ar.date_from = a6.date_from
