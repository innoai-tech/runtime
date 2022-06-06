import { BehaviorSubject, catchError, from, mergeMap, Observable, Subject, tap } from "rxjs";
import type { Fetcher, FetcherErrorResponse, FetcherResponse, RequestConfigCreator } from "./fetcher";

export class RequestSubject<TInputs, TBody, TError> extends Observable<FetcherResponse<TInputs, TBody>> {
  requesting$ = new BehaviorSubject<boolean>(false);
  error$ = new Subject<FetcherErrorResponse<TInputs, TError>>();
  _success$ = new Subject<FetcherResponse<TInputs, TBody>>();
  _input$ = new Subject<TInputs>();

  constructor(private fetcher: Fetcher, private createConfig: RequestConfigCreator<TInputs, TBody>) {
    super((subscriber) => {
      return this._success$.subscribe(subscriber);
    });

    this._input$
      .pipe(
        mergeMap((input) => {
          this.requesting$.next(true);

          return from(fetcher.request<TInputs, TBody>(createConfig(input)));
        }),
        tap((resp) => {
          return this._success$.next(resp);
        }),
        catchError((errorResp) => {
          this.error$.next(errorResp);
          return errorResp;
        }),
        tap(() => {
          this.requesting$.next(false);
        }),
      )
      .subscribe();
  }

  next(value: TInputs) {
    this._input$.next(value);
  }

  toHref(value: TInputs): string {
    return this.fetcher.toHref(this.createConfig(value));
  }
}

export interface StandardRespError {
  code: number;
  msg: string;
  desc: string;
}
