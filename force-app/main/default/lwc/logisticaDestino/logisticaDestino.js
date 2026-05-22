import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getDestinoData from '@salesforce/apex/LogisticaDashboardController.getDestinoData';
import getCasesByEstado from '@salesforce/apex/LogisticaDashboardController.getCasesByEstado';

const REFRESH_INTERVAL_MS = 5 * 60 * 1000; // 5 minutos

const COLORS = ['#04844B', '#1B2945', '#0176D3', '#747474', '#F4B95C', '#E45B25', '#8A2BE2', '#D81B60'];

export default class LogisticaDestino extends NavigationMixin(LightningElement) {
    _data = [];
    _wiredResult;
    _refreshTimer;
    _countdownTimer;
    @track _seconds = REFRESH_INTERVAL_MS / 1000;
    isLoading = true;
    errorMessage = '';

    @track modalOpen = false;
    @track modalTitle = '';
    @track modalCases = [];
    @track isLoadingCases = false;

    @wire(getDestinoData)
    wiredData(result) {
        this._wiredResult = result;
        this.isLoading = false;
        if (result.data) this._data = result.data;
        else if (result.error) this.errorMessage = result.error?.body?.message ?? 'Erro ao carregar dados.';
    }

    connectedCallback() {
        this._refreshTimer = setInterval(() => {
            refreshApex(this._wiredResult);
            this._seconds = REFRESH_INTERVAL_MS / 1000;
        }, REFRESH_INTERVAL_MS);

        this._countdownTimer = setInterval(() => {
            this._seconds = this._seconds > 0 ? this._seconds - 1 : 0;
        }, 1000);
    }

    disconnectedCallback() {
        clearInterval(this._refreshTimer);
        clearInterval(this._countdownTimer);
    }

    get countdown() {
        const m = Math.floor(this._seconds / 60);
        const s = this._seconds % 60;
        return `${m}:${s.toString().padStart(2, '0')}`;
    }

    get enrichedData() {
        return this._data.map((item, idx) => {
            const color = COLORS[idx % COLORS.length];
            return {
                ...item,
                widthStyle: `width:${item.percentage}%; background-color:${color};`,
                dotStyle: `background-color:${color};`,
                tooltipText: `${item.label}: ${item.percentage}%`,
                formattedPct: String(item.percentage)
            };
        });
    }

    get hasData() { return this._data.length > 0; }
    get hasError() { return this.errorMessage !== ''; }
    get hasModalCases() { return this.modalCases.length > 0; }

    handleStateClick(event) {
        const uf    = event.currentTarget.dataset.uf;
        const label = event.currentTarget.dataset.label;
        this.modalTitle      = label;
        this.modalOpen       = true;
        this.isLoadingCases  = true;
        this.modalCases      = [];

        getCasesByEstado({ uf })
            .then(data  => { this.modalCases = data; this.isLoadingCases = false; })
            .catch(()   => { this.isLoadingCases = false; });
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
