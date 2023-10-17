<?php

$randArray = [];

for ($i = 0; $i < 1000; $i++)
{
    $randArray[] = $i;
}

shuffle($randArray);
$i = 0;

echo "rand_tab_lo:" . PHP_EOL;

foreach ($randArray as $item)
{
    if ($i % 8)
    {
        echo sprintf("0x%02X", ($item & 0xFF));

        if (($i % 8) < 7)
        {
            echo ', ';
        }
        else
        {
            echo PHP_EOL;
        }
    }
    else
    {
         echo "  !byte " . sprintf("0x%02X", ($item & 0xFF)) . ', ';
    }

    $i++;
}

echo "rand_tab_hi:" . PHP_EOL;

foreach ($randArray as $item)
{
    if ($i % 8)
    {
        echo sprintf("0x%02X", (($item >> 8) & 0xFF));

        if (($i % 8) < 7)
        {
            echo ', ';
        }
        else
        {
            echo PHP_EOL;
        }
    }
    else
    {
         echo "  !byte " . sprintf("0x%02X", (($item >> 8) & 0xFF)) . ', ';
    }

    $i++;
}
