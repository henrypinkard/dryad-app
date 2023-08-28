/* eslint-disable */
import React, {useRef, useEffect, useState} from 'react';
import tar from 'tar-stream';

export default function Download(){

  const downloadOnClick = async () => {
    // from https://css-tricks.com/getting-started-with-the-file-system-access-api/ and
    // https://github.com/mafintosh/tar-stream

    // tar packing
    const pack = tar.pack() // pack is a stream

    // add a file called my-test.txt with the content "Hello World!"
    pack.entry({ name: 'my-test.txt' }, 'Hello World!');

    // add a file called my-stream-test.txt from a stream
    const entry = pack.entry({ name: 'my-stream-test.txt', size: 11 }, function(err) {
      // the stream was added
      // no more entries
      pack.finalize()
      if (err) {
        console.error(err);
        return;
      }
      pack.finalize();
    })

    entry.write('hello');
    entry.write(' ');
    entry.write('world');
    entry.end();

    // stuff to manage file system access
    const options = {
      types: [
        {
          description: "Test files",
          accept: {
            "application/x-tar": [".tar"],
          },
        },
      ],
    };

    const handle = await window.showSaveFilePicker(options);
    const writable = await handle.createWritable();
    // const writer = await writeable.getWriter();

    pack.pipe(writable);

    await new Promise((resolve, reject) => {
      // pack.on('error', reject);
      pack.on('finish', () => {
        resolve();
      });
    });

    await writable.close();
    return handle;
  }

  return (
      <>
        <button onClick={downloadOnClick}>Click to test download</button>
      </>
  );
}