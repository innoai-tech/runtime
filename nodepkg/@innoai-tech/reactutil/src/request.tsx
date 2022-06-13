import { createFetcher, RequestSubject } from "@innoai-tech/fetcher";
import { createContext, ReactNode, useContext, useMemo } from "react";
import { paramsSerializer, transformRequestBody } from "@innoai-tech/fetcher";

export interface RequestConfig<TInputs> {
  method: string;
  url: string;
  params?: { [k: string]: any };
  headers?: { [k: string]: any };
  body?: { [k: string]: any };
  inputs: TInputs;
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

export interface FetcherErrorResponse<TInputs extends any, TError extends any>
  extends FetcherResponse<TInputs, any> {
  error: TError;
}

export interface Fetcher {
  toHref: (requestConfig: RequestConfig<any>) => string;
  request: <TInputs extends any, TData extends any>(requestConfig: RequestConfig<TInputs>) => Promise<FetcherResponse<TInputs, TData>>;
}

const FetcherContext = createContext<{ fetcher?: Fetcher }>({});

export const FetcherProvider = ({
                                  fetcher,
                                  children,
                                }: {
  fetcher: Fetcher;
  children: ReactNode;
}) => {
  return (
    <FetcherContext.Provider value={{ fetcher: fetcher }}>
      {children}
    </FetcherContext.Provider>
  );
};

const useFetcher = () => {
  return useContext(FetcherContext).fetcher || createFetcher({
    paramsSerializer,
    transformRequestBody,
  });
};

export interface RespError {
  code: number;
  msg: string;
  desc: string;
}

export const useRequest = <TReq, TRespData>(
  createConfig: RequestConfigCreator<TReq, TRespData>,
) => {
  const fetcher = useFetcher();

  return useMemo(() => {
    return new RequestSubject<TReq, TRespData, RespError>(
      fetcher,
      createConfig,
    );
  }, [fetcher]);
};
