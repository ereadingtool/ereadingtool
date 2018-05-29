/**
 * @license Copyright (c) 2003-2018, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see https://ckeditor.com/legal/ckeditor-oss-license
 */

CKEDITOR.editorConfig = function(config) {
    config.startupFocus = true;

    config.toolbarGroups = [
        {name: "insert", groups: ["insert"]},
        {name: "links", groups: ["links"]},
        {name: "clipboard", groups: ["clipboard", "undo"]},
        {name: "paragraph", groups: ["list", "indent", "blocks", "align", "bidi", "paragraph"]},
        {name: "document", groups: ["mode", "document", "doctools"]},
        "/",
        {name: "basicstyles", groups: ["basicstyles", "cleanup"]},
        {name: "styles", groups: ["styles"]},
        {name: "colors", groups: ["colors"]},
        {name: "editing", groups: ["find", "selection", "spellchecker", "editing"]},
        {name: "forms", groups: ["forms"]},
        {name: "tools", groups: ["tools"]},
        {name: "others", groups: ["others"]},
        {name: "about", groups: ["about"]}];

    config.removeButtons = "Flash,HorizontalRule,Smiley,PageBreak,Iframe," +
        "Anchor,Save,NewPage,Preview,Print,Templates,Cut,Copy,Paste,PasteText," +
        "PasteFromWord,Find,Replace,SelectAll,Scayt,Form,Checkbox,Radio,TextField," +
        "Textarea,Select,Button,ImageButton,HiddenField,Strike,CopyFormatting,Blockquote," +
        "CreateDiv,Styles,Format,Maximize,ShowBlocks,About";
};