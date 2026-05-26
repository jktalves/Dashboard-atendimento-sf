import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getTransportadoraData from '@salesforce/apex/LogisticaDashboardController.getTransportadoraData';
import getCasesByTransportadora from '@salesforce/apex/LogisticaDashboardController.getCasesByTransportadora';

const REFRESH_INTERVAL_MS = 5 * 60 * 1000;

const COLORS = ['#0176D3', '#04844B', '#F4B95C', '#E45B25', '#747474', '#8A2BE2', '#D81B60', '#1B2945'];

export default class LogisticaTransportadora extends NavigationMixin(LightningElement) {
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

    @wire(getTransportadoraData, { period: '$_period' })
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

    get totalChamados() {
        return this._data.reduce((sum, item) => sum + item.count, 0);
    }

    get enrichedData() {
        return this._data.map((item, idx) => {
            const color = COLORS[idx % COLORS.length];
            return {
                ...item,
                rank: idx + 1,
                widthStyle: `width:${item.percentage}%; background-color:${color};`,
                dotStyle: `background-color:${color};`,
                miniBarStyle: `width:${item.percentage}%; background-color:${color};`,
                badgeStyle: `background-color:${color}33; color:${color};`,
                rankStyle: `background-color:${color}22; color:${color}; border:1px solid ${color}55;`,
                tooltipText: `${item.label}: ${item.percentage}%`,
                formattedPct: String(item.percentage)
            };
        });
    }

    get hasData() { return this._data.length > 0; }
    get hasError() { return this.errorMessage !== ''; }
    get hasModalCases() { return this.modalCases.length > 0; }

    handleTranspClick(event) {
        const transp = event.currentTarget.dataset.transp;
        this.modalTitle     = transp;
        this.modalOpen      = true;
        this.isLoadingCases = true;
        this.modalCases     = [];

        getCasesByTransportadora({ transp, period: this._period })
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
