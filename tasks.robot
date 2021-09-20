*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Robocloud.Secrets
Library           RPA.Archive
Library           RPA.Dialogs

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    10x
${GLOBAL_RETRY_INTERVAL}=    1s

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    [Documentation]    Order robots from RobotSpareBin Industries Inc
    Get The URL From Vault And Open The Robot Order Website
    ${orders}=    Get Orders
    FOR    ${row}    IN    @{orders}
        Close The Annoying Modal
        Fill The Form    ${row}
        Preview The Robot
        Submit The Order
        ${pdf}=    Store The Receipt As A PDF File    ${row}[Order number]
        ${screenshot}=    Take A Screenshot Of The Robot    ${row}[Order number]
        Embed The Robot Screenshot To The Receipt PDF File    ${screenshot}    ${pdf}
        Go To Order Another Robot
    END
    Create A ZIP File Of The Receipts

*** Keywords ***
Get The URL From Vault And Open The Robot Order Website
    [Documentation]    Getting url from vault and opening the website
    ${url}=    Get Secret    credentials
    Log    ${url}
    Open Available Browser    ${url}[website]

Collect Excel File From User
    [Documentation]    Collecting excel file from user
    Add Heading    Enter url of the csv file
    Add Text Input    name=url
    ${result}=    Run Dialog
    [Return]    ${result.url}

Get Orders
    [Documentation]    Getting Orders
    ${csv_url}=    Collect Excel File From User
    Download    ${csv_url}    overwrite=True
    ${table}=    Read Table From Csv    orders.csv    dialect=excel    header=True
    FOR    ${row}    IN    @{table}
        Log    ${row}
    END
    [Return]    ${table}

Close The Annoying Modal
    [Documentation]    Closing pop-up
    Click Button    OK

Fill The Form
    [Documentation]    Filling the form
    [Arguments]    ${row_here}
    ${head}=    Convert To Integer    ${row_here}[Head]
    ${body}=    Convert To Integer    ${row_here}[Body]
    ${legs}=    Convert To Integer    ${row_here}[Legs]
    ${address}=    Convert To String    ${row_here}[Address]
    Select From List By Value    id:head    ${head}
    Click Element    id-body-${body}
    Input Text    id:address    ${address}
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${legs}

Placing The Order And Checking
    [Documentation]    Placing the order and making sure it works
    Click Element    order
    Element Should Be Visible    xpath://div[@id="receipt"]/p[1]
    Element Should Be Visible    id:order-completion

Preview The Robot
    [Documentation]    Previewing the robot
    Click Element    id:preview
    Wait Until Element Is Visible    id:robot-preview

Submit The Order
    [Documentation]    Submitting the order
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Placing The Order And Checking

Store The Receipt As A PDF File
    [Documentation]    Storing as pdf
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:order-completion
    ${order_number}=    Get Text    xpath://div[@id="receipt"]/p[1]
    ${receipt}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf

Take A Screenshot Of The Robot
    [Documentation]    Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview    ${CURDIR}${/}output${/}${order_number}.png
    [Return]    ${CURDIR}${/}output${/}${order_number}.png

Embed The Robot Screenshot To The Receipt PDF File
    [Documentation]    Embed the robot screenshot to the receipt pdf file
    [Arguments]    ${image}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${image}    ${pdf}
    Close Pdf    ${pdf}

Go To Order Another Robot
    [Documentation]    Ordering another robot
    Click Button    order-another

Create A ZIP File Of The Receipts
    [Documentation]    Create A ZIP File Of The Receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipts    ${CURDIR}${/}output${/}receipt.zip
