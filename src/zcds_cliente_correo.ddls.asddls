@AbapCatalog.sqlViewName: 'ZCDS_CLI_MAIL'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista correo del Cliente'
@Metadata.ignorePropagatedAnnotations: true
define view zview_cliente_correo 
    as select from kna1 as cl
//    
    association[0..1] to adr6 as a6  on $projection.adrnr = a6.addrnumber
                                    and a6.flgdefault = 'X'
                                    and a6.persnumber = ' '
{
    key cl.kunnr,
    key cl.adrnr,
        a6.smtp_addr
}
