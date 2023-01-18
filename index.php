<!DOCTYPE html>
<html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta http-equiv='X-UA-Compatible' content='IE=edge'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>OpenVPN</title>
        <style>
            body {
                margin: 0;
                padding: 0;
                width: 100vw;
                height: 100vh;
                overflow: hidden;
                position: relative;
                text-align: center;
                scroll-behavior: smooth;
                color: rgb(255, 255, 255);
                font-family: 'Inter', 'Roboto', 'Arial', sans-serif;
                background: linear-gradient(165deg, rgb(20, 252, 195) 0%, rgb(136, 20, 252) 100%);
            }

            table {
                top: 50%;
                left: 50%;
                padding: 40px;
                position: absolute;
                border-radius: 10px;
                letter-spacing: normal;
                transform: translate(-50%, -50%);
                background-color: rgb(30, 30, 30);
            }

            h1 {
                font-size: 18px;
                padding: 10px 40px;
                border-radius: 10px;
                margin-bottom: 20px;
                color: rgb(255, 193, 7);
                border: 2px rgb(255, 193, 7) solid;
            }

            input {
                width: 100%;
                font-size: 24px;
                line-height: 2rem;
                padding: 10px 40px;
                border-radius: 10px;
                color: rgb(255, 255, 255);
                background-color: transparent;
                border: 2px rgb(255, 255, 255) solid;
            }

            input:hover {
                background-color: rgba(255, 255, 255, 0.1);
            }
        </style>
    </head>
    <body>
        <table>
            <tr>
                <td>
                    <?php
                        $file = 'client.ovpn';

                        if (array_key_exists('download', $_GET)) {
                            download($file);
                        } else if (array_key_exists('delete', $_GET)) {
                            delete($file);
                        }

                        function download($file) {
                            if(file_exists($file)) {
                                header('Location: download.php');

                                die();
                            } else {
                                notify('Could not find configuration file...');
                            }
                        }

                        function delete($file) {
                            if (!unlink($file)) {
                                notify('Could not delete configuration file...');
                            }
                            else {
                                notify('Configuration has been deleted...');
                            }
                        }

                        function notify($message) {
                            echo ('<h1>' . $message . '</h1>');
                        }
                    ?>
                </td>
            </tr>
            <tr>
                <td>
                    <form method='get'>
                        <input type='submit' name='download' value='Download' style='margin-bottom: 20px;' />
                    </form>
                </td>
            </tr>
            <tr>
                <td>
                    <form method='get'>
                        <input type='submit' name='delete' value='Delete' />
                    </form>
                </td>
            </tr>
        </table>
    </body>
</html>