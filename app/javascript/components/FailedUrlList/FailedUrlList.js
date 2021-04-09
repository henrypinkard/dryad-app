import React from "react";

import Url from "./Url/Url";
import classes from './FailedUrlList.module.css';

const failed_url_list = (props) => {
    return (
        <div>
            <h1 className={classes.UrlValidationTitle}>Validation Status</h1>
            {props.failedUrls.map((url, index) => {
                return <Url
                    key={index}
                    click={() => props.clicked(index)}
                    url={url}
                />
            })}
        </div>
    )
}

export default failed_url_list;