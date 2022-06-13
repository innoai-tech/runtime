import type { FunctionComponent, ReactElement } from "react";
import { useEffect, useMemo, useState } from "react";
import { BehaviorSubject, merge, Observable, tap } from "rxjs";
import { isFunction } from "@innoai-tech/lodash";

export type ArrayOrNone<T> = T | T[] | undefined;

export const useObservableEffect = (
  effect: () => ArrayOrNone<Observable<any>>,
  deps: any[] = [],
) => {
  useEffect(() => {
    const ob = effect();
    if (!ob) {
      return;
    }
    const sub = merge(...([] as Array<Observable<any>>).concat(ob)).subscribe();
    return () => sub.unsubscribe();
  }, deps);
};

interface ObservableWithValue<T> extends Observable<T> {
  value: T;
}

export function useObservable<T extends any>(ob$: ObservableWithValue<T>): T
export function useObservable<T extends any>(ob$: Observable<T>): T | null
export function useObservable<T extends any>(ob$: Observable<T> | ObservableWithValue<T>): T | null {
  const [s, up] = useState(() => (ob$ as any).value);
  useObservableEffect(() => ob$.pipe(tap((resp) => up(resp))), [ob$]);
  return s;
}

export class StateSubject<T> extends BehaviorSubject<T> {
  override next(value: T | ((value: T) => T)) {
    super.next(isFunction(value) ? value(super.value) : value);
  }
}

export const useStateSubject = <T extends any>(initialValue: T | (() => T)) => {
  return useMemo(() => {
    return new StateSubject<T>(
      isFunction(initialValue) ? initialValue() : initialValue,
    );
  }, []);
};

export function Subscribe<T extends any>(props: { value$: ObservableWithValue<T>, children: (v: T) => ReactElement | null }): ReturnType<FunctionComponent>
export function Subscribe<T extends any>(props: { value$: Observable<T> | ObservableWithValue<T>, children: (v: T | null) => ReturnType<FunctionComponent> }): ReturnType<FunctionComponent> {
  const s = useObservable<T>(props.value$);
  return props.children(s);
}
