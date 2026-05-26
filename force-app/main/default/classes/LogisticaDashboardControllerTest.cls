@IsTest(SeeAllData=true)
private class LogisticaDashboardControllerTest {

    @IsTest
    static void testGetDestinoData() {
        Test.startTest();
        List<Map<String, Object>> result = LogisticaDashboardController.getDestinoData('MES');
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
        result = LogisticaDashboardController.getDestinoData('ANO');
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
        Test.stopTest();
    }

    @IsTest
    static void testGetTransportadoraData() {
        Test.startTest();
        List<Map<String, Object>> result = LogisticaDashboardController.getTransportadoraData('MES');
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
        result = LogisticaDashboardController.getTransportadoraData('ANO');
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
        Test.stopTest();
    }

    @IsTest
    static void testGetCasesByEstado() {
        Test.startTest();
        List<Map<String, Object>> result = LogisticaDashboardController.getCasesByEstado('SP', 'MES');
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
        Test.stopTest();
    }

    @IsTest
    static void testGetCasesByTransportadora() {
        Test.startTest();
        List<Map<String, Object>> result = LogisticaDashboardController.getCasesByTransportadora('Jadlog.com', 'MES');
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
        Test.stopTest();
    }

    @IsTest
    static void testGetTypeData() {
        Test.startTest();
        List<Map<String, Object>> result = LogisticaDashboardController.getTypeData('MES');
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
        result = LogisticaDashboardController.getTypeData('ANO');
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
        Test.stopTest();
    }

    @IsTest
    static void testGetCasesByType() {
        Test.startTest();
        List<Map<String, Object>> result = LogisticaDashboardController.getCasesByType('Entregas', 'MES');
        System.assertNotEquals(null, result, 'Resultado não deve ser nulo');
        Test.stopTest();
    }
}
