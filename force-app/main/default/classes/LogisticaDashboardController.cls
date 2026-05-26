public with sharing class LogisticaDashboardController {

    private static final Map<String, String> UF_TO_ESTADO = new Map<String, String>{
        'AC'=>'Acre','AL'=>'Alagoas','AP'=>'Amapá','AM'=>'Amazonas',
        'BA'=>'Bahia','CE'=>'Ceará','DF'=>'Distrito Federal',
        'ES'=>'Espírito Santo','GO'=>'Goiás','MA'=>'Maranhão',
        'MT'=>'Mato Grosso','MS'=>'Mato Grosso do Sul','MG'=>'Minas Gerais',
        'PA'=>'Pará','PB'=>'Paraíba','PR'=>'Paraná','PE'=>'Pernambuco',
        'PI'=>'Piauí','RJ'=>'Rio de Janeiro','RN'=>'Rio Grande do Norte',
        'RS'=>'Rio Grande do Sul','RO'=>'Rondônia','RR'=>'Roraima',
        'SC'=>'Santa Catarina','SP'=>'São Paulo','SE'=>'Sergipe','TO'=>'Tocantins'
    };

    private static final Set<String> TRANSPORTADORAS = new Set<String>{
        'DHL', 'J&T', 'Jadlog.com', 'Jadlog Package', 'Latam é Fácil', 'Latam Standard', 'Transportadora Log 10',
        'Endereço do Cliente', 'Loggi', 'Correios', 'Escritório Aluga', 'Total Express'
    };

    private static final Set<String> TIPOS = new Set<String>{
        'Entregas', 'Retiradas', 'Trocas', 'Logística - Entrega', 'Logística - Retiradas',
        'Problema', 'Solicitação', 'Pendência', 'Software', 'Assistência Técnica', 'Migração', 'Movimentação Interna'
    };

    private static final Set<String> STATUS_FILTER = new Set<String>{ 'Fechado' };

    private static final List<String> TIPOS_ATENDIMENTO = new List<String>{
        'Entregas', 'Retiradas', 'Trocas', 'Logística - Entrega', 'Logística - Retiradas',
        'Problema', 'Solicitação', 'Pendência', 'Software', 'Assistência Técnica', 'Migração', 'Movimentação Interna'
    };

    private static Date getStartDate(String period) {
        if ('ANO'.equals(period)) return Date.newInstance(Date.today().year(), 1, 1);
        return Date.today().toStartOfMonth();
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getDestinoData(String period) {
        Date startDate = getStartDate(period);
        List<AggregateResult> allResults = [
            SELECT Endere_o__r.Estado__c uf, COUNT(Id) total
            FROM Case
            WHERE CreatedDate >= :startDate
              AND Endere_o__r.Estado__c != null
              AND Op_es_de_Entrega__c IN :TRANSPORTADORAS
              AND Type IN :TIPOS
              AND Status IN :STATUS_FILTER
            WITH USER_MODE
            GROUP BY Endere_o__r.Estado__c
            ORDER BY COUNT(Id) DESC
        ];

        Integer grandTotal = 0;
        for (AggregateResult ar : allResults) {
            grandTotal += (Integer) ar.get('total');
        }

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (AggregateResult ar : allResults) {
            String uf   = (String) ar.get('uf');
            Integer cnt = (Integer) ar.get('total');
            Decimal pct = grandTotal > 0 ? (cnt * 100.0 / grandTotal).setScale(2) : 0;
            rows.add(new Map<String, Object>{
                'label'      => UF_TO_ESTADO.containsKey(uf) ? UF_TO_ESTADO.get(uf) : uf,
                'uf'         => uf,
                'count'      => cnt,
                'percentage' => pct
            });
        }
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getTransportadoraData(String period) {
        Date startDate = getStartDate(period);
        List<AggregateResult> queryResults = [
            SELECT Op_es_de_Entrega__c transp, COUNT(Id) total
            FROM Case
            WHERE CreatedDate >= :startDate
              AND Op_es_de_Entrega__c IN :TRANSPORTADORAS
              AND Type IN :TIPOS
              AND Status IN :STATUS_FILTER
            WITH USER_MODE
            GROUP BY Op_es_de_Entrega__c
        ];

        Map<String, Integer> countMap = new Map<String, Integer>();
        Integer grandTotal = 0;
        for (AggregateResult ar : queryResults) {
            Integer cnt = (Integer) ar.get('total');
            countMap.put((String) ar.get('transp'), cnt);
            grandTotal += cnt;
        }

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (String transp : TRANSPORTADORAS) {
            Integer cnt = countMap.containsKey(transp) ? countMap.get(transp) : 0;
            Decimal pct = grandTotal > 0 ? (cnt * 100.0 / grandTotal).setScale(2) : 0;
            rows.add(new Map<String, Object>{
                'label'      => transp,
                'count'      => cnt,
                'percentage' => pct
            });
        }
        rows.sort(new DescCount());
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getTypeData(String period) {
        Date startDate = getStartDate(period);
        List<AggregateResult> queryResults = [
            SELECT Type tipo, COUNT(Id) total
            FROM Case
            WHERE CreatedDate >= :startDate
              AND Type IN :TIPOS_ATENDIMENTO
              AND Status IN :STATUS_FILTER
            WITH USER_MODE
            GROUP BY Type
        ];

        Map<String, Integer> countMap = new Map<String, Integer>();
        Integer grandTotal = 0;
        for (AggregateResult ar : queryResults) {
            Integer cnt = (Integer) ar.get('total');
            countMap.put((String) ar.get('tipo'), cnt);
            grandTotal += cnt;
        }

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (String tipo : TIPOS_ATENDIMENTO) {
            Integer cnt = countMap.containsKey(tipo) ? countMap.get(tipo) : 0;
            Decimal pct = grandTotal > 0 ? (cnt * 100.0 / grandTotal).setScale(2) : 0;
            rows.add(new Map<String, Object>{
                'label'      => tipo,
                'count'      => cnt,
                'percentage' => pct
            });
        }
        rows.sort(new DescCount());
        return rows;
    }

    private class DescCount implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            return (Integer) b.get('count') - (Integer) a.get('count');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCasesByEstado(String uf, String period) {
        Date startDate = getStartDate(period);
        List<Case> cases = [
            SELECT Id, CaseNumber, Cidade_formula__c, Op_es_de_Entrega__c, CreatedDate
            FROM Case
            WHERE CreatedDate >= :startDate
              AND Endere_o__r.Estado__c = :uf
              AND Op_es_de_Entrega__c IN :TRANSPORTADORAS
              AND Type IN :TIPOS
              AND Status IN :STATUS_FILTER
            WITH USER_MODE
            ORDER BY Cidade_formula__c ASC NULLS LAST
            LIMIT 200
        ];
        return toRows(cases);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCasesByTransportadora(String transp, String period) {
        Date startDate = getStartDate(period);
        List<Case> cases = [
            SELECT Id, CaseNumber, Cidade_formula__c, Endere_o__r.Estado__c, CreatedDate
            FROM Case
            WHERE CreatedDate >= :startDate
              AND Op_es_de_Entrega__c = :transp
              AND Type IN :TIPOS
              AND Status IN :STATUS_FILTER
            WITH USER_MODE
            ORDER BY Cidade_formula__c ASC NULLS LAST
            LIMIT 200
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Case c : cases) {
            String estado = c.Endere_o__r != null ? c.Endere_o__r.Estado__c : '';
            rows.add(new Map<String, Object>{
                'id'           => c.Id,
                'caseNumber'   => c.CaseNumber,
                'cidade'       => c.Cidade_formula__c,
                'estado'       => UF_TO_ESTADO.containsKey(estado) ? UF_TO_ESTADO.get(estado) : estado,
                'dataAgendada' => c.CreatedDate != null ? c.CreatedDate.format() : ''
            });
        }
        return rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCasesByType(String tipo, String period) {
        Date startDate = getStartDate(period);
        List<Case> cases = [
            SELECT Id, CaseNumber, Cidade_formula__c, Op_es_de_Entrega__c, Endere_o__r.Estado__c, CreatedDate
            FROM Case
            WHERE CreatedDate >= :startDate
              AND Type = :tipo
              AND Status IN :STATUS_FILTER
            WITH USER_MODE
            ORDER BY Cidade_formula__c ASC NULLS LAST
            LIMIT 200
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Case c : cases) {
            String estado = c.Endere_o__r != null ? c.Endere_o__r.Estado__c : '';
            rows.add(new Map<String, Object>{
                'id'             => c.Id,
                'caseNumber'     => c.CaseNumber,
                'cidade'         => c.Cidade_formula__c,
                'transportadora' => c.Op_es_de_Entrega__c,
                'estado'         => UF_TO_ESTADO.containsKey(estado) ? UF_TO_ESTADO.get(estado) : estado,
                'dataAgendada'   => c.CreatedDate != null ? c.CreatedDate.format() : ''
            });
        }
        return rows;
    }

    private static List<Map<String, Object>> toRows(List<Case> cases) {
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Case c : cases) {
            rows.add(new Map<String, Object>{
                'id'             => c.Id,
                'caseNumber'     => c.CaseNumber,
                'cidade'         => c.Cidade_formula__c,
                'transportadora' => c.Op_es_de_Entrega__c,
                'dataAgendada'   => c.CreatedDate != null ? c.CreatedDate.format() : ''
            });
        }
        return rows;
    }
}
