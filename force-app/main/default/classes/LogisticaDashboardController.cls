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
        'DHL', 'J&T', 'Jadlog.com', 'Jadlog Package', 'Latam é Fácil', 'Transportadora Log 10'
    };

    private static final Set<String> TIPOS = new Set<String>{
        'Logística - Entrega', 'Trocas', 'Entregas'
    };

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getDestinoData() {
        List<AggregateResult> allResults = [
            SELECT Endere_o__r.Estado__c uf, COUNT(Id) total
            FROM Case
            WHERE Data_Agendada__c = LAST_N_DAYS:30
              AND Endere_o__r.Estado__c != null
              AND Op_es_de_Entrega__c IN :TRANSPORTADORAS
              AND Type IN :TIPOS
            WITH USER_MODE
            GROUP BY Endere_o__r.Estado__c
            ORDER BY COUNT(Id) DESC
        ];

        Integer grandTotal = 0;
        for (AggregateResult ar : allResults) {
            grandTotal += (Integer) ar.get('total');
        }

        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Integer i = 0; i < Math.min(10, allResults.size()); i++) {
            AggregateResult ar = allResults[i];
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
    public static List<Map<String, Object>> getTransportadoraData() {
        List<AggregateResult> queryResults = [
            SELECT Op_es_de_Entrega__c transp, COUNT(Id) total
            FROM Case
            WHERE Data_Agendada__c = LAST_N_DAYS:30
              AND Op_es_de_Entrega__c IN :TRANSPORTADORAS
              AND Type IN :TIPOS
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

    private class DescCount implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            return (Integer) b.get('count') - (Integer) a.get('count');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCasesByEstado(String uf) {
        List<Case> cases = [
            SELECT Id, CaseNumber, Cidade_formula__c, Op_es_de_Entrega__c, Data_Agendada__c
            FROM Case
            WHERE Data_Agendada__c = LAST_N_DAYS:30
              AND Endere_o__r.Estado__c = :uf
              AND Op_es_de_Entrega__c IN :TRANSPORTADORAS
              AND Type IN :TIPOS
            WITH USER_MODE
            ORDER BY Cidade_formula__c ASC NULLS LAST
            LIMIT 200
        ];
        return toRows(cases);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCasesByTransportadora(String transp) {
        List<Case> cases = [
            SELECT Id, CaseNumber, Cidade_formula__c, Endere_o__r.Estado__c, Data_Agendada__c
            FROM Case
            WHERE Data_Agendada__c = LAST_N_DAYS:30
              AND Op_es_de_Entrega__c = :transp
              AND Type IN :TIPOS
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
                'dataAgendada' => c.Data_Agendada__c != null ? c.Data_Agendada__c.format() : ''
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
                'dataAgendada'   => c.Data_Agendada__c != null ? c.Data_Agendada__c.format() : ''
            });
        }
        return rows;
    }
}
