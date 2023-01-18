<?php
    $file = 'client.ovpn';

    if(file_exists($file)) {
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header("Cache-Control: no-cache, must-revalidate");
        header("Expires: 0");
        header('Content-Disposition: attachment; filename="client.ovpn"');
        header('Content-Length: ' . filesize($file));
        header('Pragma: public');

        flush();

        readfile($file);

        die();
    } else {
        echo "Could not find configuration...";
    }
?>
