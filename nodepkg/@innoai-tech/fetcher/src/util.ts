import { forEach, isArray, isObject, isUndefined } from "@innoai-tech/lodash";

export const stringifySearch = (query: { [k: string]: string[] }): string => {
  const p = new URLSearchParams();
  forEach(query, (vv, k) => {
    forEach(vv, (v) => {
      p.append(k, v);
    });
  });
  return `?` + p.toString();
};

export const parseSearch = (s: string): { [k: string]: string[] } => {
  if (s[0] == "?") {
    s = s.slice(1);
  }
  const p = new URLSearchParams(s);
  const labels: { [k: string]: string[] } = {};
  for (const k in p) {
    labels[k] = p.getAll(k);
  }
  return labels;
};

const getContentType = (headers: any = {}) => headers["Content-Type"] || headers["content-type"] || "";

const isContentTypeMultipartFormData = (headers: any) => getContentType(headers).includes("multipart/form-data");
const isContentTypeFormURLEncoded = (headers: any) =>
  getContentType(headers).includes("application/x-www-form-urlencoded");

export const paramsSerializer = (params: any): string => {
  const searchParams = new URLSearchParams();

  const append = (k: string, v: any) => {
    if (isArray(v)) {
      forEach(v, (vv) => {
        append(k, vv);
      });
      return;
    }
    if (isObject(v)) {
      append(k, JSON.stringify(v));
      return;
    }
    if (isUndefined(v) || `${v}`.length == 0) {
      return;
    }
    searchParams.append(k, `${v}`);
  };

  forEach(params, (v, k) => {
    append(k, v);
  });

  return searchParams.toString();
};

export const transformRequestBody = (data: any, headers: any) => {
  if (isContentTypeMultipartFormData(headers)) {
    const formData = new FormData();

    const appendValue = (k: string, v: any) => {
      if (v instanceof File || v instanceof Blob) {
        formData.append(k, v);
      } else if (isArray(v)) {
        forEach(v, (item) => appendValue(k, item));
      } else if (isObject(v)) {
        formData.append(k, JSON.stringify(v));
      } else {
        formData.append(k, v as string);
      }
    };

    forEach(data, (v, k) => appendValue(k, v));

    return formData;
  }

  if (isContentTypeFormURLEncoded(headers)) {
    return paramsSerializer(data);
  }

  if (isArray(data) || isObject(data)) {
    return JSON.stringify(data);
  }

  return data;
};
