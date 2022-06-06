export interface RequestConfig<TInputs> {
  method: string;
  url: string;
  inputs: TInputs;
  params?: { [k: string]: any };
  headers?: { [k: string]: any };
  body?: any;
}

export interface RequestConfigCreator<TInputs, TRespData> {
  (input: TInputs): RequestConfig<TInputs>;

  TRespData: TRespData;
}

export interface FetcherResponse<TInputs, TData> {
  config: RequestConfig<TInputs>;
  status: number;
  headers: { [k: string]: string };
  body: TData;
}

export interface FetcherErrorResponse<TInputs extends any, TError extends any> extends FetcherResponse<TInputs, any> {
  error: TError;
}

export interface Fetcher {
  toHref: (requestConfig: RequestConfig<any>) => string;
  request: <TInputs extends any, TData extends any>(
    requestConfig: RequestConfig<TInputs>,
  ) => Promise<FetcherResponse<TInputs, TData>>;
}

export interface FetcherCreatorOptions {
  paramsSerializer: (params: any) => string;
  transformRequestBody: (data: any, headers: { [k: string]: any }) => BodyInit;
}

export type FetcherCreator = (options: FetcherCreatorOptions) => Fetcher;

export type RequestInterceptor = (requestConfig: RequestConfig<any>) => RequestConfig<any>;

export const applyRequestInterceptors =
  (...requestInterceptors: RequestInterceptor[]) =>
    (fetcher: Fetcher) => {
      return {
        request: <TInputs extends any, TRespData extends any>(requestConfig: RequestConfig<TInputs>) => {
          for (const requestInterceptor of requestInterceptors) {
            requestConfig = requestInterceptor(requestConfig);
          }
          return fetcher.request<TInputs, TRespData>(requestConfig);
        },
        toHref: (requestConfig: RequestConfig<any>): string => {
          for (const requestInterceptor of requestInterceptors) {
            requestConfig = requestInterceptor(requestConfig);
          }
          return fetcher.toHref(requestConfig);
        },
      };
    };
