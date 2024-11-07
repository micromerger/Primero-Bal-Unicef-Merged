// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import { fromJS } from "immutable";
import { useDispatch } from "react-redux";

import useMemoizedSelector from "../../libs/use-memoized-selector";

import { setFormFilters, clearFormFilters } from "./action-creators";
import { getFormFilters } from "./selectors";

export const useFormFilters = formName => {
  const dispatch = useDispatch();

  const formFilters = useMemoizedSelector(state => getFormFilters(state));
  const selectedFilters = formFilters.get(formName) || fromJS({});

  const handleSetFormFilters = payload => dispatch(setFormFilters(formName, payload));
  const handleClearFilters = () => dispatch(clearFormFilters(formName));

  return { clearFilters: handleClearFilters, selectedFilters, setFormFilters: handleSetFormFilters };
};

export default useFormFilters;
