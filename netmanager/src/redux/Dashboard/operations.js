// for representing chained operations using redux-thunk
import axios from "axios";
import {
  REFRESH_FILTER_LOCATION_DATA_SUCCESS,
  REFRESH_FILTER_LOCATION_DATA_ERROR,
  LOAD_USER_DEFAULT_GRAPHS_SUCCESS,
  LOAD_USER_DEFAULT_GRAPHS_ERROR,
  SET_USER_DEFAULTS_GRAPHS_SUCCESS,
  SET_USER_DEFAULTS_GRAPHS_ERROR,
} from "./actions";
import constants from "../../config/constants";

export const refreshFilterLocationData = () => {
  return async (dispatch) => {
    return await fetch(constants.GET_MONITORING_SITES_LOCATIONS_URI)
      .then((res) => res.json())
      .then((filterLocationsData) => {
        dispatch({
          type: REFRESH_FILTER_LOCATION_DATA_SUCCESS,
          payload: filterLocationsData.airquality_monitoring_sites,
        });
      })
      .catch((err) => {
        dispatch({
          type: REFRESH_FILTER_LOCATION_DATA_ERROR,
          payload: err,
        });
      });
  };
};

export const loadUserDefaultGraphData = () => {
  return async (dispatch, getState) => {
    const user = getState().auth.user._id;
    return await axios
      .get(constants.DEFAULTS_URI, { params: { user } })
      .then((res) => res.data)
      .then((userDefaultsData) => {
        const { defaults } = userDefaultsData;
        dispatch({
          type: LOAD_USER_DEFAULT_GRAPHS_SUCCESS,
          payload: defaults,
        });
      })
      .catch((err) => {
        dispatch({
          type: LOAD_USER_DEFAULT_GRAPHS_ERROR,
          payload: err,
        });
      });
  };
};

export const setUserDefaultGraphData = (filter) => {
  return async (dispatch, getState) => {
    const user = getState().auth.user._id;
    const { chartTitle } = filter;
    return await axios
      .put(constants.DEFAULTS_URI, filter, { params: { user, chartTitle } })
      .then((res) => res.data)
      .then((responseData) => {
        dispatch({
          type: SET_USER_DEFAULTS_GRAPHS_SUCCESS,
          payload: responseData,
        });
      })
      .catch((err) => {
        dispatch({
          type: SET_USER_DEFAULTS_GRAPHS_ERROR,
          payload: err,
        });
      });
  };
};
