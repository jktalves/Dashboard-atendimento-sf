import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getTypeData from '@salesforce/apex/LogisticaDashboardController.getTypeData';
import getCasesByType from '@salesforce/apex/LogisticaDashboardController.getCasesByType';

const REFRESH_INTERVAL_MS = 5 * 60 * 1000;

const COLORS = ['#0176D3', '#04844B', '#F4B95C', '#E45B25', '#8A2BE2'];

export default class PorcentagemDeAtendimento extends NavigationMixin(LightningElement) {
    _data = [];
    _wiredResult;
    _refreshTimer;
    @track _period = 'MES';
    isLoading = true;
    errorMessage = '';

    @track modalOpen = false;
    @track modalTitle = '';
    @track modalCases = [];
    @track isLoadingCases = false;

    @wire(getTypeData, { period: '$_period' })
    wiredData(result) {
        this._wiredResult = result;
        this.isLoading = false;
        if (result.data) this._data = result.data;
        else if (result.error) this.errorMessage = result.error?.body?.message ?? 'Erro ao carregar dados.';
    }

    connectedCallback() {
        this._refreshTimer = setInterval(() => {
            refreshApex(this._wiredResult);
        }, REFRESH_INTERVAL_MS);
    }

    disconnectedCallback() {
        clearInterval(this._refreshTimer);
    }

    get btnMesClass() { return 'period-btn' + (this._period === 'MES' ? ' active' : ''); }
    get btnAnoClass() { return 'period-btn' + (this._period === 'ANO' ? ' active' : ''); }

    selectMes() { this._period = 'MES'; this.isLoading = true; this._data = []; }
    selectAno() { this._period = 'ANO'; this.isLoading = true; this._data = []; }

    get enrichedData() {
        return this._data.map((item, idx) => {
            const color = COLORS[idx % COLORS.length];
            return {
                ...item,
                widthStyle: `width:${item.percentage}%; background-color:${color};`,
                dotStyle: `background-color:${color};`,
                miniBarStyle: `width:${item.percentage}%; background-color:${color};`,
                badgeStyle: `background-color:${color}33; color:${color};`,
                tooltipText: `${item.label}: ${item.percentage}%`,
                formattedPct: String(item.percentage)
            };
        });
    }

    get totalChamados() {
        return this._data.reduce((sum, item) => sum + item.count, 0);
    }

    get hasData() { return this._data.length > 0; }
    get hasError() { return this.errorMessage !== ''; }
    get hasModalCases() { return this.modalCases.length > 0; }

    handleTypeClick(event) {
        const tipo  = event.currentTarget.dataset.tipo;
        const label = event.currentTarget.dataset.label;
        this.modalTitle     = label;
        this.modalOpen      = true;
        this.isLoadingCases = true;
        this.modalCases     = [];

        getCasesByType({ tipo, period: this._period })
            .then(data => { this.modalCases = data; this.isLoadingCases = false; })
            .catch(()  => { this.isLoadingCases = false; });
    }

    closeModal() { this.modalOpen = false; }

    stopPropagation(event) { event.stopPropagation(); }

    navigateToCase(event) {
        event.preventDefault();
        const caseId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: caseId, actionName: 'view' }
        });
    }
}
