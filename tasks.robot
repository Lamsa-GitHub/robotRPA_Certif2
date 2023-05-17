*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the csv order file
    Get orders
    Create ZIP package from PDF files
    Close the robot order website


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order    maximized=True

Download the csv order file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    Wait Until Page Contains Element    css:.modal-header

Get orders
    ${orders}=    Read table from CSV    orders.csv    header=${True}
    FOR    ${order}    IN    @{orders}
        Close an annoying modal
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    1 min    10 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    order-another
    END

Close an annoying modal
    Click Button    css:.btn.btn-dark

Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    #    Execute Javascript    window.scrollBy(0, 300)
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Page Contains Element    order-completion

Store the receipt as a PDF file
    [Arguments]    ${row}
    ${receipt_html}=    Get Element Attribute    order-completion    outerHTML
    ${pdf}=    Set Variable    ${OUTPUT DIR}${/}${row}
    Html To Pdf    ${receipt_html}    ${pdf}.pdf
    Wait Until Page Contains Element    robot-preview-image
    Wait Until Page Contains Element    xpath://*[@id="robot-preview-image"]/img[1]
    Wait Until Page Contains Element    xpath://*[@id="robot-preview-image"]/img[2]
    Wait Until Page Contains Element    xpath://*[@id="robot-preview-image"]/img[3]
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${row}
    #Todo: Take a screenshot of the robot with argument and return the result
    ${screenshot}=    Set Variable    ${OUTPUT DIR}${/}${row}
    Screenshot    robot-preview-image    ${screenshot}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${receipt_pdf}=    Set Variable    receipt
    ${receipt_pdf}=    Catenate    SEPARATOR=_    ${pdf}    ${receipt_pdf}
    Open Pdf    ${pdf}.pdf
    Add Watermark Image To Pdf    ${screenshot}.png    ${receipt_pdf}.pdf
    Close Pdf

Create ZIP package from PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}    robot.zip

Close the robot order website
    Close Browser
