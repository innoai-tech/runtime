import type { Fetcher, FetcherCreatorOptions, FetcherErrorResponse, FetcherResponse, RequestConfig } from "../fetcher";

export const createFetcher = ({ paramsSerializer, transformRequestBody }: FetcherCreatorOptions): Fetcher => {
  return {
    toHref: (requestConfig: RequestConfig<any>) => {
      return `${requestConfig.url}?${paramsSerializer(requestConfig.params)}`;
    },
    request: <TInputs extends any, TRespData extends any>(requestConfig: RequestConfig<TInputs>) => {
      const reqInit: RequestInit = {
        method: requestConfig.method,
        headers: requestConfig.headers || {},
        body: transformRequestBody(requestConfig.body, requestConfig.headers || {}),
      };

      return fetch(`${requestConfig.url}?${paramsSerializer(requestConfig.params)}`, reqInit)
        .then(async (res) => {
          let body: any;

          if (res.headers.get("Content-Type")?.includes("application/json")) {
            body = await res.json();
          } else if (res.headers.get("Content-Type")?.includes("application/octet-stream")) {
            body = await res.blob();
          } else {
            body = await res.text();
          }

          const resp: any = {
            config: requestConfig,
            status: res.status,
            headers: {},
          };

          res.headers.forEach((value, key) => {
            resp.headers[key] = value;
          });

          resp.body = body as TRespData;

          return resp as FetcherResponse<TInputs, TRespData>;
        })
        .then((resp) => {
          if (resp.status >= 400) {
            (resp as FetcherErrorResponse<TInputs, any>).error = resp.body;
            throw resp;
          }
          return resp;
        });
    },
  };
};
