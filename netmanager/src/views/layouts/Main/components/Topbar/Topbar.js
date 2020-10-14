import React, { useState, Component, useEffect } from "react";
import clsx from "clsx";
import PropTypes from "prop-types";
import { Link as RouterLink } from "react-router-dom";
import { connect } from "react-redux";
import { makeStyles } from "@material-ui/styles";
import {
  AppBar,
  Toolbar,
  Badge,
  Hidden,
  IconButton,
  Typography,
  MenuItem,
  Menu,
} from "@material-ui/core";
import MenuIcon from "@material-ui/icons/Menu";
import NotificationsIcon from "@material-ui/icons/NotificationsOutlined";
import InputIcon from "@material-ui/icons/Input";
import FindInPageIcon from '@material-ui/icons/FindInPage';
import HelpIcon from '@material-ui/icons/Help';
import { logoutUser } from "redux/Join/actions";
import { useOrgData } from "../../../../../redux/Join/selectors";

const useStyles = makeStyles((theme) => ({
  root: {
    boxShadow: "none",
    backgroundColor: "#3067e2",
  },
  flexGrow: {
    flexGrow: 1,
  },
  signOutButton: {
    marginLeft: theme.spacing(1),
  },
}));

function withMyHook(Component) {
  return function WrappedComponent(props) {
    const classes = useStyles();
    return <Component {...props} classes={classes} />;
  };
}

const Topbar = (props) => {
  const divProps = Object.assign({}, props);
  delete divProps.layout;
  const { className, onSidebarOpen, ...rest } = props;

  const classes = useStyles();

  const [notifications] = useState([]);
  const orgData = useOrgData();

  const kcca_logo_style = {
    height: "3.5em",
    width: "4em",
    borderRadius: "15%",
    paddingTop: ".2em",
    marginRight: ".4em",
  };
  const mak_logo_style = {
    height: "3.3em",
    width: "4em",
    borderRadius: "15%",
    paddingTop: ".2em",
    marginRight: ".4em",
  };
  const airqo_logo_style = {
    height: "3.5em",
    width: "5em",
    paddingTop: ".2em",
    marginRight: ".4em",
  };

  const onLogoutClick = (e) => {
    e.preventDefault();
    props.logoutUser();
  };

  const timer_style = {
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    width: "100%",
    fontSize: 20,
    fontWeight: "bold",
  };

  /***
   * Handling the menue details.
   */

  const [anchorEl, setAnchorEl] = React.useState(null);
  const open = Boolean(anchorEl);

  const handleOpenMenu = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleCloseMenu = () => {
    setAnchorEl(null);
  };

  const handleAccountClick = () => {
    setAnchorEl(null);
  };

  const handleProfileClick = () => {
    setAnchorEl(null);
  };

  const [date, setDate] = React.useState(new Date());
  useEffect(() => {
    var timerID = setInterval(() => tick(), 1000);

    return function cleanup() {
      clearInterval(timerID);
    };
  }, []);
  function appendLeadingZeroes(n) {
    if (n <= 9) {
      return "0" + n;
    }
    return n;
  }

  function tick() {
    //setDate(new Date());
    let newTime = new Date();
    let time =
      appendLeadingZeroes(newTime.getDate()) +
      "-" +
      appendLeadingZeroes(newTime.getMonth() + 1) +
      "-" +
      newTime.getFullYear() +
      " " +
      appendLeadingZeroes(newTime.getHours()) +
      ":" +
      appendLeadingZeroes(newTime.getMinutes()) +
      ":" +
      appendLeadingZeroes(newTime.getSeconds());
    setDate(time);
  }

  return (
    <AppBar {...rest} className={clsx(classes.root, className)}>
      <Toolbar>
        <RouterLink to="/">
          <img
            alt="Logo"
            style={kcca_logo_style}
            src="/images/logos/kcca-logo.jpg"
          />
        </RouterLink>
        <RouterLink to="/">
          <img
            alt="airqo.net"
            style={airqo_logo_style}
            src="/images/logos/airqo_logo.png"
          />
        </RouterLink>
        <RouterLink to="/">
          <img
            alt="mak.ac.ug"
            style={mak_logo_style}
            src="/images/logos/mak_logo.jpg"
          />
        </RouterLink>
        <div
          style={{
            textTransform: "uppercase",
            marginLeft: "10px",
            fontSize: 20,
            fontWeight: "bold",
          }}
        >
          {orgData.name}
        </div>
        <p style={timer_style}>
          <span>{date.toLocaleString()}</span>
        </p>
        <div className={classes.flexGrow} />
        <Hidden mdDown>
        <a style={{
            textTransform: "uppercase",
            marginLeft: "10px",
            fontSize: 16,
            fontWeight: "bold",
            color:'#fff' ,
          }} href="https://docs.airqo.net/airqo-handbook/-MHlrqORW-vI38ybYLVC/" target='_blank'>
          
          <HelpIcon/>
        </a>
       
          <IconButton color="inherit">
            <Badge
              badgeContent={notifications.length}
              color="primary"
              variant="dot"
            >
              <NotificationsIcon />
            </Badge>
          </IconButton>
          <IconButton
            className={classes.signOutButton}
            color="inherit"
            onClick={handleOpenMenu}
          >
            <InputIcon />
          </IconButton>
          <Menu
            id="menu-appbar"
            anchorEl={anchorEl}
            anchorOrigin={{
              vertical: "top",
              horizontal: "right",
            }}
            keepMounted
            transformOrigin={{
              vertical: "top",
              horizontal: "right",
            }}
            open={open}
            onClose={handleCloseMenu}
          >
            <MenuItem onClick={handleProfileClick}>Settings</MenuItem>
            <MenuItem onClick={handleAccountClick}>Account</MenuItem>
            <MenuItem onClick={onLogoutClick}>Logout</MenuItem>
          </Menu>
        </Hidden>
      </Toolbar>
    </AppBar>
  );
};

Topbar.propTypes = {
  className: PropTypes.string,
  onSidebarOpen: PropTypes.func,
  logoutUser: PropTypes.func.isRequired,
  auth: PropTypes.object.isRequired,
};

const mapStateToProps = (state) => ({
  auth: state.auth,
});

export default connect(mapStateToProps, { logoutUser })(withMyHook(Topbar));
