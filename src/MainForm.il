.class private abstract sealed auto ansi beforefieldinit FolderMap.Ui
    extends [mscorlib]System.Object
{
    .method public hidebysig static void Add(
        class [System.Windows.Forms]System.Windows.Forms.Control parent,
        class [System.Windows.Forms]System.Windows.Forms.Control child) cil managed
    {
        .maxstack 2
        ldarg.0
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.Control/ControlCollection [System.Windows.Forms]System.Windows.Forms.Control::get_Controls()
        ldarg.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control/ControlCollection::Add(class [System.Windows.Forms]System.Windows.Forms.Control)
        ret
    }

    .method public hidebysig static class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel Table(int32 columns, int32 rows) cil managed
    {
        .maxstack 2
        .locals init (class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel table)
        newobj instance void [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel::.ctor()
        stloc table
        ldloc table
        ldc.i4.5
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Dock(valuetype [System.Windows.Forms]System.Windows.Forms.DockStyle)
        ldloc table
        ldarg.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel::set_ColumnCount(int32)
        ldloc table
        ldarg.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel::set_RowCount(int32)
        ldloc table
        ldc.i4.0
        newobj instance void [System.Windows.Forms]System.Windows.Forms.Padding::.ctor(int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Margin(valuetype [System.Windows.Forms]System.Windows.Forms.Padding)
        ldloc table
        ret
    }

    .method public hidebysig static void Row(
        class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel table,
        float32 size, bool percent) cil managed
    {
        .maxstack 3
        ldarg.0
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TableLayoutRowStyleCollection [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel::get_RowStyles()
        ldarg.2
        ldc.i4.1
        add
        ldarg.1
        newobj instance void [System.Windows.Forms]System.Windows.Forms.RowStyle::.ctor(valuetype [System.Windows.Forms]System.Windows.Forms.SizeType, float32)
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.TableLayoutRowStyleCollection::Add(class [System.Windows.Forms]System.Windows.Forms.RowStyle)
        pop
        ret
    }

    .method public hidebysig static void Column(
        class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel table,
        float32 size, bool percent) cil managed
    {
        .maxstack 3
        ldarg.0
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TableLayoutColumnStyleCollection [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel::get_ColumnStyles()
        ldarg.2
        ldc.i4.1
        add
        ldarg.1
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ColumnStyle::.ctor(valuetype [System.Windows.Forms]System.Windows.Forms.SizeType, float32)
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.TableLayoutColumnStyleCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ColumnStyle)
        pop
        ret
    }

    .method public hidebysig static void Place(
        class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel table,
        class [System.Windows.Forms]System.Windows.Forms.Control control,
        int32 column, int32 row) cil managed
    {
        .maxstack 4
        ldarg.0
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TableLayoutControlCollection [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel::get_Controls()
        ldarg.1
        ldarg.2
        ldarg.3
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TableLayoutControlCollection::Add(class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ret
    }

    .method public hidebysig static class [System.Windows.Forms]System.Windows.Forms.Button Button(string text, string name) cil managed
    {
        .maxstack 5
        .locals init (class [System.Windows.Forms]System.Windows.Forms.Button button)
        newobj instance void [System.Windows.Forms]System.Windows.Forms.Button::.ctor()
        stloc button
        ldloc button
        ldarg.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
        ldloc button
        ldarg.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Name(string)
        ldloc button
        ldc.i4.5
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Dock(valuetype [System.Windows.Forms]System.Windows.Forms.DockStyle)
        ldloc button
        ldc.i4.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ButtonBase::set_FlatStyle(valuetype [System.Windows.Forms]System.Windows.Forms.FlatStyle)
        ldloc button
        ldc.i4.s 30
        ldc.i4.s 41
        ldc.i4.s 59
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::FromArgb(int32, int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_BackColor(valuetype [System.Drawing]System.Drawing.Color)
        ldloc button
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::get_White()
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_ForeColor(valuetype [System.Drawing]System.Drawing.Color)
        ldloc button
        ldc.i4.4
        ldc.i4.5
        ldc.i4.4
        ldc.i4.5
        newobj instance void [System.Windows.Forms]System.Windows.Forms.Padding::.ctor(int32, int32, int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Margin(valuetype [System.Windows.Forms]System.Windows.Forms.Padding)
        ldloc button
        ret
    }

    .method public hidebysig static class [System.Windows.Forms]System.Windows.Forms.Label Label(string text) cil managed
    {
        .maxstack 4
        .locals init (class [System.Windows.Forms]System.Windows.Forms.Label label)
        newobj instance void [System.Windows.Forms]System.Windows.Forms.Label::.ctor()
        stloc label
        ldloc label
        ldarg.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
        ldloc label
        ldc.i4.5
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Dock(valuetype [System.Windows.Forms]System.Windows.Forms.DockStyle)
        ldloc label
        ldc.i4.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Label::set_AutoEllipsis(bool)
        ldloc label
        ldc.i4.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Label::set_UseMnemonic(bool)
        ldloc label
        ldc.i4.s 16
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Label::set_TextAlign(valuetype [System.Drawing]System.Drawing.ContentAlignment)
        ldloc label
        ldc.i4 226
        ldc.i4 232
        ldc.i4 240
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::FromArgb(int32, int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_ForeColor(valuetype [System.Drawing]System.Drawing.Color)
        ldloc label
        ret
    }

    .method public hidebysig static void AddChoice(
        class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem parent,
        string text, int32 option, class [mscorlib]System.EventHandler callback, bool chosen) cil managed
    {
        .maxstack 2
        .locals init (class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem item)
        ldarg.1
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::.ctor(string)
        stloc item
        ldloc item
        ldarg.2
        box [mscorlib]System.Int32
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_Tag(object)
        ldloc item
        ldarg.s chosen
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::set_Checked(bool)
        ldloc item
        ldc.i4.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::set_CheckOnClick(bool)
        ldloc item
        ldarg.3
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStripDropDownItem::get_DropDownItems()
        ldloc item
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ret
    }

    .method public hidebysig static void CheckChoice(
        class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem parent, int32 option) cil managed
    {
        .maxstack 3
        .locals init (int32 index, class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem item)
        ldc.i4.0
        stloc index
        br CHECK
    ITEM:
        ldarg.0
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStripDropDownItem::get_DropDownItems()
        ldloc index
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItem [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::get_Item(int32)
        castclass [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem
        stloc item
        ldloc item
        ldloc item
        callvirt instance object [System.Windows.Forms]System.Windows.Forms.ToolStripItem::get_Tag()
        unbox.any [mscorlib]System.Int32
        ldarg.1
        ceq
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::set_Checked(bool)
        ldloc index
        ldc.i4.1
        add
        stloc index
    CHECK:
        ldloc index
        ldarg.0
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStripDropDownItem::get_DropDownItems()
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::get_Count()
        blt ITEM
        ret
    }
}

.class public auto ansi beforefieldinit FolderMap.MainForm
    extends [System.Windows.Forms]System.Windows.Forms.Form
{
    .field public class FolderMap.ScanResult LastResult
    .field public class FolderMap.FolderNode CurrentFolder
    .field public string LastError
    .field public string CacheDirectory
    .field private class [System.Windows.Forms]System.Windows.Forms.TextBox pathBox
    .field private class [System.Windows.Forms]System.Windows.Forms.Button browseButton
    .field private class [System.Windows.Forms]System.Windows.Forms.Button scanButton
    .field private class [System.Windows.Forms]System.Windows.Forms.Button cancelButton
    .field private class [System.Windows.Forms]System.Windows.Forms.Button upButton
    .field private class [System.Windows.Forms]System.Windows.Forms.Label pathLabel
    .field private class [System.Windows.Forms]System.Windows.Forms.Label summaryLabel
    .field private class [System.Windows.Forms]System.Windows.Forms.TreeView tree
    .field private class FolderMap.TreemapView map
    .field private class [System.Windows.Forms]System.Windows.Forms.ToolStripStatusLabel statusLabel
    .field private string selectionDetails
    .field private string scanMessage
    .field private valuetype FolderMap.ScanCacheMode scanCacheMode
    .field private class [System]System.Diagnostics.Stopwatch scanClock
    .field private class [System.Windows.Forms]System.Windows.Forms.ToolStripProgressBar progress
    .field private class [System.Windows.Forms]System.Windows.Forms.ToolStripButton issuesButton
    .field private class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip folderMenu
    .field private class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem exitMenuItem
    .field private class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem fullScanMenuItem
    .field private class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem retryCacheMenuItem
    .field private class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem restartMenuItem
    .field private class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem algorithmMenu
    .field private class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem colorsMenu
    .field private class [System]System.ComponentModel.BackgroundWorker worker
    .field private class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode> treeIndex
    .field private class [System.Drawing]System.Drawing.Font bodyFont
    .field private class [System.Drawing]System.Drawing.Font titleFont
    .field private class [System.Drawing]System.Drawing.Font pathFont
    .field private bool cancellationRequested
    .field private bool closing
    .field private bool autoStart

    .method public hidebysig specialname rtspecialname instance void .ctor() cil managed
    {
        .maxstack 4
        ldarg.0
        call instance void [System.Windows.Forms]System.Windows.Forms.Form::.ctor()
        ldarg.0
        newobj instance void [System]System.Diagnostics.Stopwatch::.ctor()
        stfld class [System]System.Diagnostics.Stopwatch FolderMap.MainForm::scanClock
        ldarg.0
        call string FolderMap.CacheStore::DefaultDirectory()
        stfld string FolderMap.MainForm::CacheDirectory
        ldarg.0
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::SuspendLayout()
        ldarg.0
        ldstr "FolderMap - MSIL / CIL - x64"
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
        ldarg.0
        ldc.i4 1280
        ldc.i4 820
        newobj instance void [System.Drawing]System.Drawing.Size::.ctor(int32, int32)
        call instance void [System.Windows.Forms]System.Windows.Forms.Form::set_ClientSize(valuetype [System.Drawing]System.Drawing.Size)
        ldarg.0
        ldc.i4 980
        ldc.i4 620
        newobj instance void [System.Drawing]System.Drawing.Size::.ctor(int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_MinimumSize(valuetype [System.Drawing]System.Drawing.Size)
        ldarg.0
        ldc.i4.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Form::set_StartPosition(valuetype [System.Windows.Forms]System.Windows.Forms.FormStartPosition)
        ldarg.0
        ldc.i4.1
        call instance void [System.Windows.Forms]System.Windows.Forms.ContainerControl::set_AutoScaleMode(valuetype [System.Windows.Forms]System.Windows.Forms.AutoScaleMode)
        ldarg.0
        ldc.i4.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Form::set_KeyPreview(bool)
        ldarg.0
        ldc.i4.s 15
        ldc.i4.s 23
        ldc.i4.s 42
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::FromArgb(int32, int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_BackColor(valuetype [System.Drawing]System.Drawing.Color)
        ldarg.0
        ldstr "Segoe UI"
        ldc.r4 9
        newobj instance void [System.Drawing]System.Drawing.Font::.ctor(string, float32)
        stfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::bodyFont
        ldarg.0
        ldstr "Segoe UI"
        ldc.r4 21
        ldc.i4.1
        newobj instance void [System.Drawing]System.Drawing.Font::.ctor(string, float32, valuetype [System.Drawing]System.Drawing.FontStyle)
        stfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::titleFont
        ldarg.0
        ldstr "Segoe UI"
        ldc.r4 11
        ldc.i4.1
        newobj instance void [System.Drawing]System.Drawing.Font::.ctor(string, float32, valuetype [System.Drawing]System.Drawing.FontStyle)
        stfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::pathFont
        ldarg.0
        ldarg.0
        ldfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::bodyFont
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Font(class [System.Drawing]System.Drawing.Font)
        ldarg.0
        newobj instance void class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode>::.ctor()
        stfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode> FolderMap.MainForm::treeIndex
        ldarg.0
        call instance void FolderMap.MainForm::CreateUi()
        ldarg.0
        call instance void FolderMap.MainForm::ConnectEvents()
        ldarg.0
        ldc.i4.0
        call instance void FolderMap.MainForm::SetBusy(bool)
        ldarg.0
        ldc.i4.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::ResumeLayout(bool)
        ret
    }

    .method private hidebysig instance void CreateUi() cil managed
    {
        .maxstack 6
        .locals init (
            class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel outer,
            class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel header,
            class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel location,
            class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel navigation,
            class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel folders,
            class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel chart,
            class [System.Windows.Forms]System.Windows.Forms.Label label,
            class [System.Windows.Forms]System.Windows.Forms.SplitContainer split,
            class [System.Windows.Forms]System.Windows.Forms.StatusStrip status,
            class [System.Windows.Forms]System.Windows.Forms.MenuStrip mainMenu,
            class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem fileMenu,
            class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem editMenu,
            class [mscorlib]System.EventHandler algorithmClick,
            class [mscorlib]System.EventHandler colorClick
        )
        ldc.i4.1
        ldc.i4.5
        call class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel FolderMap.Ui::Table(int32, int32)
        stloc outer
        ldloc outer
        ldc.i4.s 12
        newobj instance void [System.Windows.Forms]System.Windows.Forms.Padding::.ctor(int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Padding(valuetype [System.Windows.Forms]System.Windows.Forms.Padding)
        ldloc outer
        ldc.r4 100
        ldc.i4.1
        call void FolderMap.Ui::Column(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc outer
        ldc.r4 60
        ldc.i4.0
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc outer
        ldc.r4 46
        ldc.i4.0
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc outer
        ldc.r4 68
        ldc.i4.0
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc outer
        ldc.r4 100
        ldc.i4.1
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        // Reserve the status strip's preferred height as fonts and DPI change.
        ldloc outer
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TableLayoutRowStyleCollection [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel::get_RowStyles()
        ldc.i4.0
        newobj instance void [System.Windows.Forms]System.Windows.Forms.RowStyle::.ctor(valuetype [System.Windows.Forms]System.Windows.Forms.SizeType)
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.TableLayoutRowStyleCollection::Add(class [System.Windows.Forms]System.Windows.Forms.RowStyle)
        pop
        ldarg.0
        ldloc outer
        call void FolderMap.Ui::Add(class [System.Windows.Forms]System.Windows.Forms.Control, class [System.Windows.Forms]System.Windows.Forms.Control)

        ldc.i4.2
        ldc.i4.1
        call class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel FolderMap.Ui::Table(int32, int32)
        stloc header
        ldloc header
        ldc.r4 45
        ldc.i4.1
        call void FolderMap.Ui::Column(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc header
        ldc.r4 55
        ldc.i4.1
        call void FolderMap.Ui::Column(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldstr "FolderMap"
        call class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.Ui::Label(string)
        stloc label
        ldloc label
        ldarg.0
        ldfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::titleFont
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Font(class [System.Drawing]System.Drawing.Font)
        ldloc header
        ldloc label
        ldc.i4.0
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldstr "Recursive disk usage  |  Written in MSIL / CIL  |  x64\r\nRead-only scanning. Logical file sizes, not allocated disk space."
        call class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.Ui::Label(string)
        stloc label
        ldloc label
        ldc.i4.s 64
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Label::set_TextAlign(valuetype [System.Drawing]System.Drawing.ContentAlignment)
        ldloc header
        ldloc label
        ldc.i4.1
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldloc outer
        ldloc header
        ldc.i4.0
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)

        ldc.i4.4
        ldc.i4.1
        call class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel FolderMap.Ui::Table(int32, int32)
        stloc location
        ldloc location
        ldc.r4 100
        ldc.i4.1
        call void FolderMap.Ui::Column(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc location
        ldc.r4 88
        ldc.i4.0
        call void FolderMap.Ui::Column(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc location
        ldc.r4 88
        ldc.i4.0
        call void FolderMap.Ui::Column(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc location
        ldc.r4 88
        ldc.i4.0
        call void FolderMap.Ui::Column(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldarg.0
        newobj instance void [System.Windows.Forms]System.Windows.Forms.TextBox::.ctor()
        stfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        ldstr "pathBox"
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Name(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        ldstr "Folder path"
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_AccessibleName(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        ldc.i4.5
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Dock(valuetype [System.Windows.Forms]System.Windows.Forms.DockStyle)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        ldc.i4.4
        ldc.i4.s 11
        ldc.i4.4
        ldc.i4.4
        newobj instance void [System.Windows.Forms]System.Windows.Forms.Padding::.ctor(int32, int32, int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Margin(valuetype [System.Windows.Forms]System.Windows.Forms.Padding)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        call string [mscorlib]System.Environment::get_CurrentDirectory()
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
        ldloc location
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        ldc.i4.0
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldarg.0
        ldstr "&Browse..."
        ldstr "browseButton"
        call class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.Ui::Button(string, string)
        stfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::browseButton
        ldarg.0
        ldstr "&Scan"
        ldstr "scanButton"
        call class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.Ui::Button(string, string)
        stfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::scanButton
        ldarg.0
        ldstr "&Cancel"
        ldstr "cancelButton"
        call class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.Ui::Button(string, string)
        stfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::cancelButton
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::scanButton
        ldc.i4.s 37
        ldc.i4.s 99
        ldc.i4 235
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::FromArgb(int32, int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_BackColor(valuetype [System.Drawing]System.Drawing.Color)
        ldloc location
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::browseButton
        ldc.i4.1
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldloc location
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::scanButton
        ldc.i4.2
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldloc location
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::cancelButton
        ldc.i4.3
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldarg.0
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::scanButton
        call instance void [System.Windows.Forms]System.Windows.Forms.Form::set_AcceptButton(class [System.Windows.Forms]System.Windows.Forms.IButtonControl)
        ldloc outer
        ldloc location
        ldc.i4.0
        ldc.i4.1
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)

        ldc.i4.2
        ldc.i4.2
        call class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel FolderMap.Ui::Table(int32, int32)
        stloc navigation
        ldloc navigation
        ldc.r4 88
        ldc.i4.0
        call void FolderMap.Ui::Column(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc navigation
        ldc.r4 100
        ldc.i4.1
        call void FolderMap.Ui::Column(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc navigation
        ldc.r4 55
        ldc.i4.1
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc navigation
        ldc.r4 45
        ldc.i4.1
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldarg.0
        ldstr "&Up"
        ldstr "upButton"
        call class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.Ui::Button(string, string)
        stfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::upButton
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::upButton
        ldc.i4.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Enabled(bool)
        ldloc navigation
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::upButton
        ldc.i4.0
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldarg.0
        ldstr "No folder scanned yet"
        call class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.Ui::Label(string)
        stfld class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.MainForm::pathLabel
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.MainForm::pathLabel
        ldarg.0
        ldfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::pathFont
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Font(class [System.Drawing]System.Drawing.Font)
        ldarg.0
        ldstr "Enter a folder path or use Browse. Expand folders to see exact recursive byte totals."
        call class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.Ui::Label(string)
        stfld class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.MainForm::summaryLabel
        ldloc navigation
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.MainForm::pathLabel
        ldc.i4.1
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldloc navigation
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.MainForm::summaryLabel
        ldc.i4.1
        ldc.i4.1
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldloc outer
        ldloc navigation
        ldc.i4.0
        ldc.i4.2
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)

        newobj instance void [System.Windows.Forms]System.Windows.Forms.SplitContainer::.ctor()
        stloc split
        ldloc split
        ldc.i4 1200
        ldc.i4 550
        newobj instance void [System.Drawing]System.Drawing.Size::.ctor(int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Size(valuetype [System.Drawing]System.Drawing.Size)
        ldloc split
        ldc.i4.5
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Dock(valuetype [System.Windows.Forms]System.Windows.Forms.DockStyle)
        ldloc split
        ldc.i4 390
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.SplitContainer::set_SplitterDistance(int32)
        ldloc split
        ldc.i4 260
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.SplitContainer::set_Panel1MinSize(int32)
        ldloc split
        ldc.i4 350
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.SplitContainer::set_Panel2MinSize(int32)
        ldloc split
        ldc.i4.7
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.SplitContainer::set_SplitterWidth(int32)
        ldc.i4.1
        ldc.i4.2
        call class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel FolderMap.Ui::Table(int32, int32)
        stloc folders
        ldloc folders
        ldc.r4 30
        ldc.i4.0
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc folders
        ldc.r4 100
        ldc.i4.1
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc folders
        ldstr "FOLDERS  /  RECURSIVE BYTES"
        call class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.Ui::Label(string)
        ldc.i4.0
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldarg.0
        newobj instance void [System.Windows.Forms]System.Windows.Forms.TreeView::.ctor()
        stfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldstr "folderTree"
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Name(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldstr "Folders and total recursive bytes"
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_AccessibleName(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldc.i4.5
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Dock(valuetype [System.Windows.Forms]System.Windows.Forms.DockStyle)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldc.i4.s 22
        ldc.i4.s 33
        ldc.i4.s 53
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::FromArgb(int32, int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_BackColor(valuetype [System.Drawing]System.Drawing.Color)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::get_WhiteSmoke()
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_ForeColor(valuetype [System.Drawing]System.Drawing.Color)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldc.i4.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::set_BorderStyle(valuetype [System.Windows.Forms]System.Windows.Forms.BorderStyle)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldc.i4.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::set_HideSelection(bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldc.i4.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::set_ShowNodeToolTips(bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldc.i4.s 26
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::set_ItemHeight(int32)
        ldloc folders
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldc.i4.0
        ldc.i4.1
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldloc split
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.SplitterPanel [System.Windows.Forms]System.Windows.Forms.SplitContainer::get_Panel1()
        ldloc folders
        call void FolderMap.Ui::Add(class [System.Windows.Forms]System.Windows.Forms.Control, class [System.Windows.Forms]System.Windows.Forms.Control)

        ldc.i4.1
        ldc.i4.3
        call class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel FolderMap.Ui::Table(int32, int32)
        stloc chart
        ldloc chart
        ldc.r4 30
        ldc.i4.0
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc chart
        ldc.r4 100
        ldc.i4.1
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc chart
        ldc.r4 30
        ldc.i4.0
        call void FolderMap.Ui::Row(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, float32, bool)
        ldloc chart
        ldstr "TREEMAP  /  AREA = BYTES"
        call class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.Ui::Label(string)
        ldc.i4.0
        ldc.i4.0
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldarg.0
        newobj instance void FolderMap.TreemapView::.ctor()
        stfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldstr "treemap"
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Name(string)
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldc.i4.5
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Dock(valuetype [System.Windows.Forms]System.Windows.Forms.DockStyle)
        ldloc chart
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldc.i4.0
        ldc.i4.1
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldloc chart
        ldstr "Click for details. Double-click to zoom. Hover for bytes. Empty / tiny folders are in the tree."
        call class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.Ui::Label(string)
        ldc.i4.0
        ldc.i4.2
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldloc split
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.SplitterPanel [System.Windows.Forms]System.Windows.Forms.SplitContainer::get_Panel2()
        ldloc chart
        call void FolderMap.Ui::Add(class [System.Windows.Forms]System.Windows.Forms.Control, class [System.Windows.Forms]System.Windows.Forms.Control)
        ldloc outer
        ldloc split
        ldc.i4.0
        ldc.i4.3
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)

        newobj instance void [System.Windows.Forms]System.Windows.Forms.StatusStrip::.ctor()
        stloc status
        ldloc status
        ldc.i4.5
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Dock(valuetype [System.Windows.Forms]System.Windows.Forms.DockStyle)
        ldloc status
        ldc.i4.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.StatusStrip::set_SizingGrip(bool)
        ldloc status
        ldc.i4.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStrip::set_ShowItemToolTips(bool)
        ldloc status
        ldc.i4.4
        ldc.i4.4
        ldc.i4.4
        ldc.i4.6
        newobj instance void [System.Windows.Forms]System.Windows.Forms.Padding::.ctor(int32, int32, int32, int32)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Padding(valuetype [System.Windows.Forms]System.Windows.Forms.Padding)
        ldloc status
        ldarg.0
        call instance valuetype [System.Drawing]System.Drawing.Color [System.Windows.Forms]System.Windows.Forms.Control::get_BackColor()
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_BackColor(valuetype [System.Drawing]System.Drawing.Color)
        ldarg.0
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripStatusLabel::.ctor()
        stfld class [System.Windows.Forms]System.Windows.Forms.ToolStripStatusLabel FolderMap.MainForm::statusLabel
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripStatusLabel FolderMap.MainForm::statusLabel
        ldc.i4.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripStatusLabel::set_Spring(bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripStatusLabel FolderMap.MainForm::statusLabel
        ldc.i4.s 16
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_TextAlign(valuetype [System.Drawing]System.Drawing.ContentAlignment)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripStatusLabel FolderMap.MainForm::statusLabel
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::get_LightSteelBlue()
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_ForeColor(valuetype [System.Drawing]System.Drawing.Color)
        ldarg.0
        ldstr "Ready. Enter = scan  |  F5 = rescan  |  Esc = cancel  |  Alt+Up = parent"
        call instance void FolderMap.MainForm::SetStatusMessage(string)
        ldarg.0
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripProgressBar::.ctor()
        stfld class [System.Windows.Forms]System.Windows.Forms.ToolStripProgressBar FolderMap.MainForm::progress
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripProgressBar FolderMap.MainForm::progress
        ldc.i4.2
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripProgressBar::set_Style(valuetype [System.Windows.Forms]System.Windows.Forms.ProgressBarStyle)
        ldarg.0
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripButton::.ctor()
        stfld class [System.Windows.Forms]System.Windows.Forms.ToolStripButton FolderMap.MainForm::issuesButton
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripButton FolderMap.MainForm::issuesButton
        ldstr "Skipped / errors (0)"
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_Text(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripButton FolderMap.MainForm::issuesButton
        call valuetype [System.Drawing]System.Drawing.Color [System.Drawing]System.Drawing.Color::get_Gold()
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_ForeColor(valuetype [System.Drawing]System.Drawing.Color)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripButton FolderMap.MainForm::issuesButton
        ldc.i4.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_Enabled(bool)
        ldloc status
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStrip::get_Items()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripStatusLabel FolderMap.MainForm::statusLabel
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldloc status
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStrip::get_Items()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripProgressBar FolderMap.MainForm::progress
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldloc status
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStrip::get_Items()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripButton FolderMap.MainForm::issuesButton
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldloc outer
        ldloc status
        ldc.i4.0
        ldc.i4.4
        call void FolderMap.Ui::Place(class [System.Windows.Forms]System.Windows.Forms.TableLayoutPanel, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ldarg.0
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip::.ctor()
        stfld class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip FolderMap.MainForm::folderMenu
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip FolderMap.MainForm::folderMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStrip::get_Items()
        ldstr "Open in File Explorer"
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::.ctor(string)
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        newobj instance void [System.Windows.Forms]System.Windows.Forms.MenuStrip::.ctor()
        stloc mainMenu
        ldloc mainMenu
        ldstr "mainMenu"
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Name(string)
        ldloc mainMenu
        ldc.i4.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Dock(valuetype [System.Windows.Forms]System.Windows.Forms.DockStyle)
        ldstr "&File"
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::.ctor(string)
        stloc fileMenu
        ldarg.0
        ldstr "E&xit"
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::.ctor(string)
        stfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::exitMenuItem
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::exitMenuItem
        ldc.i4 262259
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::set_ShortcutKeys(valuetype [System.Windows.Forms]System.Windows.Forms.Keys)
        ldarg.0
        ldstr "&Full rescan"
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::.ctor(string)
        stfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::fullScanMenuItem
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::fullScanMenuItem
        ldc.i4 131188
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::set_ShortcutKeys(valuetype [System.Windows.Forms]System.Windows.Forms.Keys)
        ldloc fileMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStripDropDownItem::get_DropDownItems()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::fullScanMenuItem
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldarg.0
        ldstr "Retry &USN cache"
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::.ctor(string)
        stfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::retryCacheMenuItem
        ldloc fileMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStripDropDownItem::get_DropDownItems()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::retryCacheMenuItem
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldarg.0
        ldstr "Restart as &administrator..."
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::.ctor(string)
        stfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::restartMenuItem
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::restartMenuItem
        call bool FolderMap.Elevation::IsAdministrator()
        ldc.i4.0
        ceq
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_Enabled(bool)
        ldloc fileMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStripDropDownItem::get_DropDownItems()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::restartMenuItem
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldloc fileMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStripDropDownItem::get_DropDownItems()
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripSeparator::.ctor()
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldloc fileMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStripDropDownItem::get_DropDownItems()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::exitMenuItem
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldloc mainMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStrip::get_Items()
        ldloc fileMenu
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldstr "&Edit"
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::.ctor(string)
        stloc editMenu
        ldarg.0
        ldstr "&Colors"
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::.ctor(string)
        stfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::colorsMenu
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnColorChanged(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        stloc colorClick
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::colorsMenu
        ldstr "&Classic"
        ldc.i4.0
        ldloc colorClick
        ldc.i4.1
        call void FolderMap.Ui::AddChoice(class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem, string, int32, class [mscorlib]System.EventHandler, bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::colorsMenu
        ldstr "&Ocean"
        ldc.i4.1
        ldloc colorClick
        ldc.i4.0
        call void FolderMap.Ui::AddChoice(class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem, string, int32, class [mscorlib]System.EventHandler, bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::colorsMenu
        ldstr "&Forest"
        ldc.i4.2
        ldloc colorClick
        ldc.i4.0
        call void FolderMap.Ui::AddChoice(class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem, string, int32, class [mscorlib]System.EventHandler, bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::colorsMenu
        ldstr "&Sunset"
        ldc.i4.3
        ldloc colorClick
        ldc.i4.0
        call void FolderMap.Ui::AddChoice(class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem, string, int32, class [mscorlib]System.EventHandler, bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::colorsMenu
        ldstr "&Grayscale"
        ldc.i4.4
        ldloc colorClick
        ldc.i4.0
        call void FolderMap.Ui::AddChoice(class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem, string, int32, class [mscorlib]System.EventHandler, bool)
        ldloc editMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStripDropDownItem::get_DropDownItems()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::colorsMenu
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldloc mainMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStrip::get_Items()
        ldloc editMenu
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop

        ldarg.0
        ldstr "&Treemaps"
        newobj instance void [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem::.ctor(string)
        stfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::algorithmMenu
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnAlgorithmChanged(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        stloc algorithmClick
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::algorithmMenu
        ldstr "&Binary"
        ldc.i4.0
        ldloc algorithmClick
        ldc.i4.1
        call void FolderMap.Ui::AddChoice(class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem, string, int32, class [mscorlib]System.EventHandler, bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::algorithmMenu
        ldstr "&Squarified"
        ldc.i4.1
        ldloc algorithmClick
        ldc.i4.0
        call void FolderMap.Ui::AddChoice(class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem, string, int32, class [mscorlib]System.EventHandler, bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::algorithmMenu
        ldstr "Slice and &dice"
        ldc.i4.2
        ldloc algorithmClick
        ldc.i4.0
        call void FolderMap.Ui::AddChoice(class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem, string, int32, class [mscorlib]System.EventHandler, bool)
        ldloc mainMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStrip::get_Items()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::algorithmMenu
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::Add(class [System.Windows.Forms]System.Windows.Forms.ToolStripItem)
        pop
        ldarg.0
        ldloc mainMenu
        call instance void [System.Windows.Forms]System.Windows.Forms.Form::set_MainMenuStrip(class [System.Windows.Forms]System.Windows.Forms.MenuStrip)
        ldarg.0
        ldloc mainMenu
        call void FolderMap.Ui::Add(class [System.Windows.Forms]System.Windows.Forms.Control, class [System.Windows.Forms]System.Windows.Forms.Control)
        ret
    }

    .method private hidebysig instance void ConnectEvents() cil managed
    {
        .maxstack 3
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::retryCacheMenuItem
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnRetryCache(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::fullScanMenuItem
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnFullScan(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::restartMenuItem
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnRestartElevated(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::exitMenuItem
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnExit(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::scanButton
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnScan(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::browseButton
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnBrowse(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::cancelButton
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnCancel(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::upButton
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnUp(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripButton FolderMap.MainForm::issuesButton
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnIssues(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnBeforeExpand(object, class [System.Windows.Forms]System.Windows.Forms.TreeViewCancelEventArgs)
        newobj instance void [System.Windows.Forms]System.Windows.Forms.TreeViewCancelEventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::add_BeforeExpand(class [System.Windows.Forms]System.Windows.Forms.TreeViewCancelEventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnTreeSelect(object, class [System.Windows.Forms]System.Windows.Forms.TreeViewEventArgs)
        newobj instance void [System.Windows.Forms]System.Windows.Forms.TreeViewEventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::add_AfterSelect(class [System.Windows.Forms]System.Windows.Forms.TreeViewEventHandler)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnTreeNodeClick(object, class [System.Windows.Forms]System.Windows.Forms.TreeNodeMouseClickEventArgs)
        newobj instance void [System.Windows.Forms]System.Windows.Forms.TreeNodeMouseClickEventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::add_NodeMouseClick(class [System.Windows.Forms]System.Windows.Forms.TreeNodeMouseClickEventHandler)
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnMapActivate(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        stfld class [mscorlib]System.EventHandler FolderMap.TreemapView::FolderActivated
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnMapSelect(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        stfld class [mscorlib]System.EventHandler FolderMap.TreemapView::SelectionChanged
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnMapContext(object, class [System.Windows.Forms]System.Windows.Forms.MouseEventArgs)
        newobj instance void [System.Windows.Forms]System.Windows.Forms.MouseEventHandler::.ctor(object, native int)
        stfld class [System.Windows.Forms]System.Windows.Forms.MouseEventHandler FolderMap.TreemapView::ContextRequested
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip FolderMap.MainForm::folderMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStrip::get_Items()
        ldc.i4.0
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItem [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::get_Item(int32)
        ldarg.0
        ldftn instance void FolderMap.MainForm::OnOpenInExplorer(object, class [mscorlib]System.EventArgs)
        newobj instance void [mscorlib]System.EventHandler::.ctor(object, native int)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::add_Click(class [mscorlib]System.EventHandler)
        ldarg.0
        newobj instance void [System]System.ComponentModel.BackgroundWorker::.ctor()
        stfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        ldc.i4.1
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::set_WorkerSupportsCancellation(bool)
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        ldc.i4.1
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::set_WorkerReportsProgress(bool)
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        ldarg.0
        ldftn instance void FolderMap.MainForm::ScanWork(object, class [System]System.ComponentModel.DoWorkEventArgs)
        newobj instance void [System]System.ComponentModel.DoWorkEventHandler::.ctor(object, native int)
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::add_DoWork(class [System]System.ComponentModel.DoWorkEventHandler)
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        ldarg.0
        ldftn instance void FolderMap.MainForm::ScanProgress(object, class [System]System.ComponentModel.ProgressChangedEventArgs)
        newobj instance void [System]System.ComponentModel.ProgressChangedEventHandler::.ctor(object, native int)
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::add_ProgressChanged(class [System]System.ComponentModel.ProgressChangedEventHandler)
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        ldarg.0
        ldftn instance void FolderMap.MainForm::ScanCompleted(object, class [System]System.ComponentModel.RunWorkerCompletedEventArgs)
        newobj instance void [System]System.ComponentModel.RunWorkerCompletedEventHandler::.ctor(object, native int)
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::add_RunWorkerCompleted(class [System]System.ComponentModel.RunWorkerCompletedEventHandler)
        ret
    }

    .method public hidebysig instance void SetInitialPath(string path) cil managed
    {
        .maxstack 2
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        ldarg.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
        ldarg.0
        ldc.i4.1
        stfld bool FolderMap.MainForm::autoStart
        ret
    }

    .method family hidebysig virtual instance void OnShown(class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 2
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Form::OnShown(class [mscorlib]System.EventArgs)
        ldarg.0
        ldfld bool FolderMap.MainForm::autoStart
        brfalse DONE
        ldarg.0
        call instance void FolderMap.MainForm::StartScan()
    DONE:
        ret
    }

    .method public hidebysig instance bool IsScanning() cil managed
    {
        .maxstack 1
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        callvirt instance bool [System]System.ComponentModel.BackgroundWorker::get_IsBusy()
        ret
    }

    .method private hidebysig instance void RefreshStatus() cil managed
    {
        .maxstack 3
        .locals init (string text)
        ldarg.0
        ldfld string FolderMap.MainForm::selectionDetails
        stloc text
        ldloc text
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brtrue MESSAGE_ONLY
        ldarg.0
        ldfld string FolderMap.MainForm::scanMessage
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brtrue DISPLAY
        ldloc text
        ldstr "\r\n"
        ldarg.0
        ldfld string FolderMap.MainForm::scanMessage
        call string [mscorlib]System.String::Concat(string, string, string)
        stloc text
        br DISPLAY
    MESSAGE_ONLY:
        ldarg.0
        ldfld string FolderMap.MainForm::scanMessage
        stloc text
    DISPLAY:
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripStatusLabel FolderMap.MainForm::statusLabel
        ldloc text
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_Text(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripStatusLabel FolderMap.MainForm::statusLabel
        ldloc text
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_ToolTipText(string)
        ret
    }

    .method private hidebysig instance void ShowScanProgress(string detail) cil managed
    {
        .maxstack 5
        ldarg.0
        ldstr "Scanning: "
        ldarg.0
        ldfld valuetype FolderMap.ScanCacheMode FolderMap.MainForm::scanCacheMode
        call string FolderMap.Display::CacheModeLabel(valuetype FolderMap.ScanCacheMode)
        ldstr " - "
        ldarg.1
        call string [mscorlib]System.String::Concat(string, string, string, string)
        call instance void FolderMap.MainForm::SetStatusMessage(string)
        ret
    }

    .method private hidebysig instance void SetCompletedStatus(string detail) cil managed
    {
        .maxstack 3
        .locals init (string message)
        ldstr "Scan completed in "
        ldarg.0
        ldfld class [System]System.Diagnostics.Stopwatch FolderMap.MainForm::scanClock
        callvirt instance int64 [System]System.Diagnostics.Stopwatch::get_ElapsedMilliseconds()
        call string FolderMap.Display::Elapsed(int64)
        ldstr "."
        call string [mscorlib]System.String::Concat(string, string, string)
        stloc message
        ldarg.1
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brtrue DISPLAY
        ldloc message
        ldstr " "
        ldarg.1
        call string [mscorlib]System.String::Concat(string, string, string)
        stloc message
    DISPLAY:
        ldarg.0
        ldloc message
        call instance void FolderMap.MainForm::SetStatusMessage(string)
        ret
    }

    .method private hidebysig instance void SetStatusMessage(string message) cil managed
    {
        .maxstack 2
        ldarg.0
        ldarg.1
        stfld string FolderMap.MainForm::scanMessage
        ldarg.0
        call instance void FolderMap.MainForm::RefreshStatus()
        ret
    }

    .method private hidebysig instance void SetSelectionDetails(class FolderMap.FolderNode folder, bool directFiles) cil managed
    {
        .maxstack 3
        ldarg.0
        ldarg.1
        ldarg.2
        call string FolderMap.Display::SelectionDetails(class FolderMap.FolderNode, bool)
        stfld string FolderMap.MainForm::selectionDetails
        ldarg.0
        call instance void FolderMap.MainForm::RefreshStatus()
        ret
    }

    .method private hidebysig instance void SetBusy(bool busy) cil managed
    {
        .maxstack 3
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        ldarg.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TextBoxBase::set_ReadOnly(bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::scanButton
        ldarg.1
        ldc.i4.0
        ceq
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Enabled(bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::fullScanMenuItem
        ldarg.1
        ldc.i4.0
        ceq
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_Enabled(bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::retryCacheMenuItem
        ldarg.1
        ldc.i4.0
        ceq
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_Enabled(bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::browseButton
        ldarg.1
        ldc.i4.0
        ceq
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Enabled(bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::cancelButton
        ldarg.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Enabled(bool)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripProgressBar FolderMap.MainForm::progress
        ldarg.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_Visible(bool)
        ret
    }

    .method public hidebysig instance void StartScan() cil managed
    {
        .maxstack 3
        ldarg.0
        ldc.i4.0
        ldc.i4.0
        call instance void FolderMap.MainForm::StartScanCore(bool, bool)
        ret
    }

    .method public hidebysig instance void StartFullScan() cil managed
    {
        .maxstack 3
        ldarg.0
        ldc.i4.1
        ldc.i4.0
        call instance void FolderMap.MainForm::StartScanCore(bool, bool)
        ret
    }

    .method private hidebysig instance void StartScanCore(bool forceFull, bool retryCache) cil managed
    {
        .maxstack 5
        .locals init (class FolderMap.ScanRequest scanRequest)
        ldarg.0
        call instance bool FolderMap.MainForm::IsScanning()
        brfalse START
        ldarg.0
        ldstr "A scan is already running. Cancel it before starting another."
        call instance void FolderMap.MainForm::SetStatusMessage(string)
        ret
    START:
        ldarg.0
        ldfld class [System]System.Diagnostics.Stopwatch FolderMap.MainForm::scanClock
        callvirt instance void [System]System.Diagnostics.Stopwatch::Restart()
        ldarg.0
        ldarg.1
        brfalse CACHE_CHECKING
        ldc.i4.1
        br CACHE_MODE_SET
    CACHE_CHECKING:
        ldc.i4.0
    CACHE_MODE_SET:
        stfld valuetype FolderMap.ScanCacheMode FolderMap.MainForm::scanCacheMode
        ldarg.0
        ldc.i4.0
        stfld bool FolderMap.MainForm::cancellationRequested
        ldarg.0
        ldnull
        stfld string FolderMap.MainForm::LastError
        ldarg.0
        ldc.i4.1
        call instance void FolderMap.MainForm::SetBusy(bool)
        ldarg.0
        ldstr "Previous results remain available until this scan finishes."
        call instance void FolderMap.MainForm::ShowScanProgress(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        callvirt instance string [System.Windows.Forms]System.Windows.Forms.Control::get_Text()
        ldarg.1
        newobj instance void FolderMap.ScanRequest::.ctor(string, bool)
        stloc scanRequest
        ldloc scanRequest
        ldarg.0
        ldfld string FolderMap.MainForm::CacheDirectory
        stfld string FolderMap.ScanRequest::CacheDirectory
        ldloc scanRequest
        ldarg.2
        stfld bool FolderMap.ScanRequest::RetryCache
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        ldloc scanRequest
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::RunWorkerAsync(object)
        ret
    }

    .method private hidebysig instance void OnAlgorithmChanged(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 2
        .locals init (int32 option)
        ldarg.1
        castclass [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem
        callvirt instance object [System.Windows.Forms]System.Windows.Forms.ToolStripItem::get_Tag()
        unbox.any [mscorlib]System.Int32
        stloc option
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldloc option
        callvirt instance void FolderMap.TreemapView::set_Algorithm(valuetype FolderMap.TreemapAlgorithm)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::algorithmMenu
        ldloc option
        call void FolderMap.Ui::CheckChoice(class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem, int32)
        ret
    }

    .method private hidebysig instance void OnColorChanged(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 2
        .locals init (int32 option)
        ldarg.1
        castclass [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem
        callvirt instance object [System.Windows.Forms]System.Windows.Forms.ToolStripItem::get_Tag()
        unbox.any [mscorlib]System.Int32
        stloc option
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldloc option
        callvirt instance void FolderMap.TreemapView::set_ColorScheme(valuetype FolderMap.ColorScheme)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem FolderMap.MainForm::colorsMenu
        ldloc option
        call void FolderMap.Ui::CheckChoice(class [System.Windows.Forms]System.Windows.Forms.ToolStripMenuItem, int32)
        ret
    }

    .method private hidebysig instance void OnRetryCache(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 3
        ldarg.0
        ldc.i4.0
        ldc.i4.1
        call instance void FolderMap.MainForm::StartScanCore(bool, bool)
        ret
    }

    .method private hidebysig instance void OnFullScan(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void FolderMap.MainForm::StartFullScan()
        ret
    }

    .method private hidebysig instance void OnRestartElevated(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 5
        .locals init (class [mscorlib]System.Exception failure, string message)
        .try
        {
            ldarg.0
            ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
            callvirt instance string [System.Windows.Forms]System.Windows.Forms.Control::get_Text()
            call bool FolderMap.Elevation::Restart(string)
            brfalse CANCELLED
            ldarg.0
            call instance void [System.Windows.Forms]System.Windows.Forms.Form::Close()
            leave DONE
        CANCELLED:
            ldarg.0
            ldstr "Administrator restart cancelled. This window remains open."
            call instance void FolderMap.MainForm::SetStatusMessage(string)
            leave DONE
        }
        catch [System]System.ComponentModel.Win32Exception
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.IO.IOException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.ArgumentException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.InvalidOperationException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.NotSupportedException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.Security.SecurityException
        {
            stloc failure
            leave FAILED
        }
    FAILED:
        ldstr "Could not restart as administrator: "
        ldloc failure
        callvirt instance string [mscorlib]System.Exception::get_Message()
        call string [mscorlib]System.String::Concat(string, string)
        stloc message
        ldarg.0
        ldloc message
        call instance void FolderMap.MainForm::SetStatusMessage(string)
        ldarg.0
        ldloc message
        ldstr "FolderMap - restart failed"
        ldc.i4.0
        ldc.i4.s 16
        call valuetype [System.Windows.Forms]System.Windows.Forms.DialogResult [System.Windows.Forms]System.Windows.Forms.MessageBox::Show(class [System.Windows.Forms]System.Windows.Forms.IWin32Window, string, string, valuetype [System.Windows.Forms]System.Windows.Forms.MessageBoxButtons, valuetype [System.Windows.Forms]System.Windows.Forms.MessageBoxIcon)
        pop
    DONE:
        ret
    }

    .method private hidebysig instance void OnExit(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void [System.Windows.Forms]System.Windows.Forms.Form::Close()
        ret
    }

    .method private hidebysig instance void OnScan(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void FolderMap.MainForm::StartScan()
        ret
    }

    .method private hidebysig instance void OnBrowse(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 2
        .locals init (class [System.Windows.Forms]System.Windows.Forms.FolderBrowserDialog dialog)
        newobj instance void [System.Windows.Forms]System.Windows.Forms.FolderBrowserDialog::.ctor()
        stloc dialog
        .try
        {
            ldloc dialog
            ldstr "Select a folder to measure recursively."
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.FolderBrowserDialog::set_Description(string)
            ldloc dialog
            ldc.i4.0
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.FolderBrowserDialog::set_ShowNewFolderButton(bool)
            ldarg.0
            ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
            callvirt instance string [System.Windows.Forms]System.Windows.Forms.Control::get_Text()
            call bool [mscorlib]System.IO.Directory::Exists(string)
            brfalse SHOW
            ldloc dialog
            ldarg.0
            ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
            callvirt instance string [System.Windows.Forms]System.Windows.Forms.Control::get_Text()
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.FolderBrowserDialog::set_SelectedPath(string)
        SHOW:
            ldloc dialog
            ldarg.0
            callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.DialogResult [System.Windows.Forms]System.Windows.Forms.CommonDialog::ShowDialog(class [System.Windows.Forms]System.Windows.Forms.IWin32Window)
            ldc.i4.1
            bne.un BROWSE_DONE
            ldarg.0
            ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
            ldloc dialog
            callvirt instance string [System.Windows.Forms]System.Windows.Forms.FolderBrowserDialog::get_SelectedPath()
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
        BROWSE_DONE:
            leave DONE
        }
        finally
        {
            ldloc dialog
            callvirt instance void [System]System.ComponentModel.Component::Dispose()
            endfinally
        }
    DONE:
        ret
    }

    .method public hidebysig instance void CancelScan() cil managed
    {
        .maxstack 2
        ldarg.0
        call instance bool FolderMap.MainForm::IsScanning()
        brtrue CANCEL
        ldarg.0
        ldstr "No scan is running."
        call instance void FolderMap.MainForm::SetStatusMessage(string)
        ret
    CANCEL:
        ldarg.0
        ldc.i4.1
        stfld bool FolderMap.MainForm::cancellationRequested
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::CancelAsync()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::cancelButton
        ldc.i4.0
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Enabled(bool)
        ldarg.0
        ldstr "Cancelling... Waiting for the current filesystem operation to return."
        call instance void FolderMap.MainForm::SetStatusMessage(string)
        ret
    }

    .method private hidebysig instance void OnCancel(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 1
        ldarg.0
        call instance void FolderMap.MainForm::CancelScan()
        ret
    }

    .method private hidebysig instance void ScanWork(object sender, class [System]System.ComponentModel.DoWorkEventArgs e) cil managed
    {
        .maxstack 5
        .locals init (class FolderMap.ScanRequest scanRequest)
        .try
        {
            ldarg.2
            callvirt instance object [System]System.ComponentModel.DoWorkEventArgs::get_Argument()
            castclass FolderMap.ScanRequest
            stloc scanRequest
            ldloc scanRequest
            ldfld bool FolderMap.ScanRequest::RetryCache
            brfalse CACHE_READY
            ldloc scanRequest
            ldfld string FolderMap.ScanRequest::Path
            ldloc scanRequest
            ldfld string FolderMap.ScanRequest::CacheDirectory
            call void FolderMap.CachedScanner::RetryCache(string, string)
        CACHE_READY:
            ldarg.2
            ldloc scanRequest
            ldfld string FolderMap.ScanRequest::Path
            ldarg.0
            ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
            ldloc scanRequest
            ldfld bool FolderMap.ScanRequest::ForceFull
            ldloc scanRequest
            ldfld string FolderMap.ScanRequest::CacheDirectory
            call class FolderMap.ScanResult FolderMap.CachedScanner::ScanWithDirectory(string, class [System]System.ComponentModel.BackgroundWorker, bool, string)
            callvirt instance void [System]System.ComponentModel.DoWorkEventArgs::set_Result(object)
            leave DONE
        }
        catch [mscorlib]System.OperationCanceledException
        {
            pop
            ldarg.2
            ldc.i4.1
            callvirt instance void [System]System.ComponentModel.CancelEventArgs::set_Cancel(bool)
            leave DONE
        }
    DONE:
        ret
    }

    .method private hidebysig instance void ScanProgress(object sender, class [System]System.ComponentModel.ProgressChangedEventArgs e) cil managed
    {
        .maxstack 3
        .locals init (class FolderMap.ScanProgressUpdate update, string detail)
        ldarg.0
        ldfld bool FolderMap.MainForm::closing
        brtrue DONE
        ldarg.0
        ldfld bool FolderMap.MainForm::cancellationRequested
        brtrue DONE
        ldarg.0
        call instance bool FolderMap.MainForm::IsScanning()
        brfalse DONE
        ldarg.2
        callvirt instance object [System]System.ComponentModel.ProgressChangedEventArgs::get_UserState()
        isinst FolderMap.ScanProgressUpdate
        stloc update
        ldloc update
        brfalse PATH_PROGRESS
        ldarg.0
        ldloc update
        ldfld valuetype FolderMap.ScanCacheMode FolderMap.ScanProgressUpdate::Mode
        stfld valuetype FolderMap.ScanCacheMode FolderMap.MainForm::scanCacheMode
        ldloc update
        ldfld string FolderMap.ScanProgressUpdate::Detail
        stloc detail
        br DISPLAY
    PATH_PROGRESS:
        ldarg.2
        callvirt instance object [System]System.ComponentModel.ProgressChangedEventArgs::get_UserState()
        castclass [mscorlib]System.String
        stloc detail
    DISPLAY:
        ldarg.0
        ldloc detail
        call instance void FolderMap.MainForm::ShowScanProgress(string)
    DONE:
        ret
    }

    .method private hidebysig instance void ScanCompleted(object sender, class [System]System.ComponentModel.RunWorkerCompletedEventArgs e) cil managed
    {
        .maxstack 6
        .locals init (class [System.Windows.Forms]System.Windows.Forms.TreeNode rootNode, string info)
        ldarg.0
        ldfld class [System]System.Diagnostics.Stopwatch FolderMap.MainForm::scanClock
        callvirt instance void [System]System.Diagnostics.Stopwatch::Stop()
        ldarg.0
        ldfld bool FolderMap.MainForm::closing
        brtrue DONE
        ldarg.0
        call instance bool [System.Windows.Forms]System.Windows.Forms.Control::get_IsDisposed()
        brtrue DONE
        ldarg.0
        ldc.i4.0
        call instance void FolderMap.MainForm::SetBusy(bool)
        ldarg.0
        ldfld bool FolderMap.MainForm::cancellationRequested
        brtrue CANCELLED
        ldarg.2
        callvirt instance bool [System]System.ComponentModel.AsyncCompletedEventArgs::get_Cancelled()
        brfalse CHECK_ERROR
    CANCELLED:
        ldarg.0
        ldstr "Scan cancelled. Previous results were kept."
        call instance void FolderMap.MainForm::SetStatusMessage(string)
        br DONE
    CHECK_ERROR:
        ldarg.2
        callvirt instance class [mscorlib]System.Exception [System]System.ComponentModel.AsyncCompletedEventArgs::get_Error()
        brfalse SUCCESS
        ldarg.0
        ldarg.2
        callvirt instance class [mscorlib]System.Exception [System]System.ComponentModel.AsyncCompletedEventArgs::get_Error()
        callvirt instance string [mscorlib]System.Object::ToString()
        stfld string FolderMap.MainForm::LastError
        ldarg.0
        ldstr "Scan failed. Previous results were kept."
        call instance void FolderMap.MainForm::SetStatusMessage(string)
        ldarg.0
        ldarg.2
        callvirt instance class [mscorlib]System.Exception [System]System.ComponentModel.AsyncCompletedEventArgs::get_Error()
        callvirt instance string [mscorlib]System.Exception::get_Message()
        ldstr "FolderMap - scan failed"
        ldc.i4.0
        ldc.i4.s 16
        call valuetype [System.Windows.Forms]System.Windows.Forms.DialogResult [System.Windows.Forms]System.Windows.Forms.MessageBox::Show(class [System.Windows.Forms]System.Windows.Forms.IWin32Window, string, string, valuetype [System.Windows.Forms]System.Windows.Forms.MessageBoxButtons, valuetype [System.Windows.Forms]System.Windows.Forms.MessageBoxIcon)
        pop
        br DONE
    SUCCESS:
        ldarg.0
        ldarg.2
        callvirt instance object [System]System.ComponentModel.RunWorkerCompletedEventArgs::get_Result()
        castclass FolderMap.ScanResult
        stfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TextBox FolderMap.MainForm::pathBox
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
        ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
        ldfld string FolderMap.FolderNode::FullPath
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::BeginUpdate()
        .try
        {
            ldarg.0
            ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode> FolderMap.MainForm::treeIndex
            callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode>::Clear()
            ldarg.0
            ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
            callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection [System.Windows.Forms]System.Windows.Forms.TreeView::get_Nodes()
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection::Clear()
            ldarg.0
            ldarg.0
            ldfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
            ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
            call instance class [System.Windows.Forms]System.Windows.Forms.TreeNode FolderMap.MainForm::CreateTreeNode(class FolderMap.FolderNode)
            stloc rootNode
            ldarg.0
            ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
            callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection [System.Windows.Forms]System.Windows.Forms.TreeView::get_Nodes()
            ldloc rootNode
            callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection::Add(class [System.Windows.Forms]System.Windows.Forms.TreeNode)
            pop
            ldloc rootNode
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeNode::Expand()
            ldarg.0
            ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
            ldloc rootNode
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::set_SelectedNode(class [System.Windows.Forms]System.Windows.Forms.TreeNode)
            ldarg.0
            ldarg.0
            ldfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
            ldfld class FolderMap.FolderNode FolderMap.ScanResult::Root
            call instance void FolderMap.MainForm::ShowFolder(class FolderMap.FolderNode)
            leave TREE_READY
        }
        finally
        {
            ldarg.0
            ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::EndUpdate()
            endfinally
        }
    TREE_READY:
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripButton FolderMap.MainForm::issuesButton
        ldstr "Skipped / errors ("
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
        ldfld int32 FolderMap.ScanResult::IssueCount
        conv.i8
        call string FolderMap.Display::Number(int64)
        ldstr ")"
        call string [mscorlib]System.String::Concat(string, string, string)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_Text(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ToolStripButton FolderMap.MainForm::issuesButton
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
        ldfld int32 FolderMap.ScanResult::IssueCount
        ldc.i4.0
        cgt
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_Enabled(bool)
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
        ldfld int32 FolderMap.ScanResult::IssueCount
        brtrue PARTIAL
        ldarg.0
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
        ldfld string FolderMap.ScanResult::CacheInfo
        call instance void FolderMap.MainForm::SetCompletedStatus(string)
        br DONE
    PARTIAL:
        ldarg.0
        ldfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
        ldfld string FolderMap.ScanResult::CacheInfo
        stloc info
        ldloc info
        call bool [mscorlib]System.String::IsNullOrEmpty(string)
        brtrue PARTIAL_MESSAGE
        ldloc info
        ldstr "\r\n"
        call string [mscorlib]System.String::Concat(string, string)
        stloc info
    PARTIAL_MESSAGE:
        ldarg.0
        ldloc info
        ldstr "Partial scan - some entries are excluded from totals. See Skipped / errors."
        call string [mscorlib]System.String::Concat(string, string)
        call instance void FolderMap.MainForm::SetCompletedStatus(string)
    DONE:
        ret
    }

    .method private hidebysig instance class [System.Windows.Forms]System.Windows.Forms.TreeNode CreateTreeNode(class FolderMap.FolderNode folder) cil managed
    {
        .maxstack 4
        .locals init (class [System.Windows.Forms]System.Windows.Forms.TreeNode node)
        ldarg.1
        call string FolderMap.Display::NodeLabel(class FolderMap.FolderNode)
        newobj instance void [System.Windows.Forms]System.Windows.Forms.TreeNode::.ctor(string)
        stloc node
        ldloc node
        ldarg.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeNode::set_Tag(object)
        ldloc node
        ldarg.1
        ldfld string FolderMap.FolderNode::FullPath
        ldstr "\r\n"
        ldarg.1
        call string FolderMap.Display::Summary(class FolderMap.FolderNode)
        call string [mscorlib]System.String::Concat(string, string, string)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeNode::set_ToolTipText(string)
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode> FolderMap.MainForm::treeIndex
        ldarg.1
        ldloc node
        callvirt instance void class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode>::Add(!0, !1)
        ldarg.1
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        brfalse DONE
        ldloc node
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection [System.Windows.Forms]System.Windows.Forms.TreeNode::get_Nodes()
        ldstr "Expand to load folders"
        newobj instance void [System.Windows.Forms]System.Windows.Forms.TreeNode::.ctor(string)
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection::Add(class [System.Windows.Forms]System.Windows.Forms.TreeNode)
        pop
    DONE:
        ldloc node
        ret
    }

    // Populate only expanded branches, rather than creating every TreeNode up front.
    .method private hidebysig instance void FillChildren(class [System.Windows.Forms]System.Windows.Forms.TreeNode parent) cil managed
    {
        .maxstack 4
        .locals init (class FolderMap.FolderNode folder, int32 index)
        ldarg.1
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection [System.Windows.Forms]System.Windows.Forms.TreeNode::get_Nodes()
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection::get_Count()
        ldc.i4.1
        bne.un DONE
        ldarg.1
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection [System.Windows.Forms]System.Windows.Forms.TreeNode::get_Nodes()
        ldc.i4.0
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNode [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection::get_Item(int32)
        callvirt instance object [System.Windows.Forms]System.Windows.Forms.TreeNode::get_Tag()
        brtrue DONE
        ldarg.1
        callvirt instance object [System.Windows.Forms]System.Windows.Forms.TreeNode::get_Tag()
        castclass FolderMap.FolderNode
        stloc folder
        ldarg.1
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection [System.Windows.Forms]System.Windows.Forms.TreeNode::get_Nodes()
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection::Clear()
        ldc.i4.0
        stloc index
        br CHECK
    ITEM:
        ldarg.1
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection [System.Windows.Forms]System.Windows.Forms.TreeNode::get_Nodes()
        ldarg.0
        ldloc folder
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        ldloc index
        callvirt instance !0 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Item(int32)
        call instance class [System.Windows.Forms]System.Windows.Forms.TreeNode FolderMap.MainForm::CreateTreeNode(class FolderMap.FolderNode)
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.TreeNodeCollection::Add(class [System.Windows.Forms]System.Windows.Forms.TreeNode)
        pop
        ldloc index
        ldc.i4.1
        add
        stloc index
    CHECK:
        ldloc index
        ldloc folder
        ldfld class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode> FolderMap.FolderNode::Children
        callvirt instance int32 class [mscorlib]System.Collections.Generic.List`1<class FolderMap.FolderNode>::get_Count()
        blt ITEM
    DONE:
        ret
    }

    .method private hidebysig instance void OnBeforeExpand(object sender, class [System.Windows.Forms]System.Windows.Forms.TreeViewCancelEventArgs e) cil managed
    {
        .maxstack 2
        ldarg.0
        ldarg.2
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNode [System.Windows.Forms]System.Windows.Forms.TreeViewCancelEventArgs::get_Node()
        call instance void FolderMap.MainForm::FillChildren(class [System.Windows.Forms]System.Windows.Forms.TreeNode)
        ret
    }

    .method private hidebysig instance void OnTreeSelect(object sender, class [System.Windows.Forms]System.Windows.Forms.TreeViewEventArgs e) cil managed
    {
        .maxstack 2
        ldarg.2
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNode [System.Windows.Forms]System.Windows.Forms.TreeViewEventArgs::get_Node()
        callvirt instance object [System.Windows.Forms]System.Windows.Forms.TreeNode::get_Tag()
        brfalse DONE
        ldarg.0
        ldarg.2
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNode [System.Windows.Forms]System.Windows.Forms.TreeViewEventArgs::get_Node()
        callvirt instance object [System.Windows.Forms]System.Windows.Forms.TreeNode::get_Tag()
        castclass FolderMap.FolderNode
        call instance void FolderMap.MainForm::ShowFolder(class FolderMap.FolderNode)
    DONE:
        ret
    }

    .method private hidebysig instance void OnTreeNodeClick(object sender, class [System.Windows.Forms]System.Windows.Forms.TreeNodeMouseClickEventArgs e) cil managed
    {
        .maxstack 5
        .locals init (class FolderMap.FolderNode folder)
        ldarg.2
        callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.MouseButtons [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Button()
        ldc.i4 2097152
        bne.un SELECT
        ldarg.2
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNode [System.Windows.Forms]System.Windows.Forms.TreeNodeMouseClickEventArgs::get_Node()
        callvirt instance object [System.Windows.Forms]System.Windows.Forms.TreeNode::get_Tag()
        isinst FolderMap.FolderNode
        stloc folder
        ldloc folder
        brfalse DONE
        ldarg.0
        ldloc folder
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldarg.2
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_X()
        ldarg.2
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Y()
        call instance void FolderMap.MainForm::ShowFolderMenu(class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ret
    SELECT:
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldfld class FolderMap.Tile FolderMap.TreemapView::SelectedTile
        brfalse DONE
        ldarg.2
        callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.MouseButtons [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Button()
        ldc.i4 1048576
        bne.un DONE
        ldarg.2
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNode [System.Windows.Forms]System.Windows.Forms.TreeNodeMouseClickEventArgs::get_Node()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.TreeNode [System.Windows.Forms]System.Windows.Forms.TreeView::get_SelectedNode()
        bne.un DONE
        ldarg.0
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.MainForm::CurrentFolder
        call instance void FolderMap.MainForm::ShowFolder(class FolderMap.FolderNode)
    DONE:
        ret
    }

    .method private hidebysig instance void ShowFolder(class FolderMap.FolderNode folder) cil managed
    {
        .maxstack 3
        ldarg.0
        ldarg.1
        stfld class FolderMap.FolderNode FolderMap.MainForm::CurrentFolder
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldarg.1
        callvirt instance void FolderMap.TreemapView::ShowFolder(class FolderMap.FolderNode)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.MainForm::pathLabel
        ldarg.1
        ldfld string FolderMap.FolderNode::FullPath
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Label FolderMap.MainForm::summaryLabel
        ldarg.1
        call string FolderMap.Display::Summary(class FolderMap.FolderNode)
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.Button FolderMap.MainForm::upButton
        ldarg.1
        ldfld class FolderMap.FolderNode FolderMap.FolderNode::Parent
        ldnull
        cgt.un
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Enabled(bool)
        ldarg.0
        ldarg.1
        ldc.i4.0
        call instance void FolderMap.MainForm::SetSelectionDetails(class FolderMap.FolderNode, bool)
        ret
    }

    .method public hidebysig instance void SelectFolder(class FolderMap.FolderNode folder) cil managed
    {
        .maxstack 3
        .locals init (
            class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode> trail,
            class FolderMap.FolderNode ancestor,
            class [System.Windows.Forms]System.Windows.Forms.TreeNode node
        )
        ldarg.1
        brtrue VALID
        ldstr "folder"
        newobj instance void [mscorlib]System.ArgumentNullException::.ctor(string)
        throw
    VALID:
        newobj instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::.ctor()
        stloc trail
        ldarg.1
        stloc ancestor
        br FIND_KNOWN
    PUSH:
        ldloc trail
        ldloc ancestor
        callvirt instance void class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::Push(!0)
        ldloc ancestor
        ldfld class FolderMap.FolderNode FolderMap.FolderNode::Parent
        stloc ancestor
        ldloc ancestor
        brtrue FIND_KNOWN
        ldstr "The selected folder does not belong to the displayed scan."
        newobj instance void [mscorlib]System.ArgumentException::.ctor(string)
        throw
    FIND_KNOWN:
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode> FolderMap.MainForm::treeIndex
        ldloc ancestor
        callvirt instance bool class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode>::ContainsKey(!0)
        brfalse PUSH
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode> FolderMap.MainForm::treeIndex
        ldloc ancestor
        callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode>::get_Item(!0)
        stloc node
        br CHECK_TRAIL
    EXPAND:
        ldarg.0
        ldloc node
        call instance void FolderMap.MainForm::FillChildren(class [System.Windows.Forms]System.Windows.Forms.TreeNode)
        ldloc node
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeNode::Expand()
        ldarg.0
        ldfld class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode> FolderMap.MainForm::treeIndex
        ldloc trail
        callvirt instance !0 class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::Pop()
        callvirt instance !1 class [mscorlib]System.Collections.Generic.Dictionary`2<class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.TreeNode>::get_Item(!0)
        stloc node
    CHECK_TRAIL:
        ldloc trail
        callvirt instance int32 class [System]System.Collections.Generic.Stack`1<class FolderMap.FolderNode>::get_Count()
        brtrue EXPAND
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.TreeView FolderMap.MainForm::tree
        ldloc node
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeView::set_SelectedNode(class [System.Windows.Forms]System.Windows.Forms.TreeNode)
        ldloc node
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.TreeNode::EnsureVisible()
        ldarg.0
        ldarg.1
        call instance void FolderMap.MainForm::ShowFolder(class FolderMap.FolderNode)
        ret
    }

    .method private hidebysig instance void ShowFolderMenu(
        class FolderMap.FolderNode folder,
        class [System.Windows.Forms]System.Windows.Forms.Control source,
        int32 x, int32 y) cil managed
    {
        .maxstack 4
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip FolderMap.MainForm::folderMenu
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripDropDown::Close()
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip FolderMap.MainForm::folderMenu
        ldarg.1
        ldfld string FolderMap.FolderNode::FullPath
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Tag(object)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip FolderMap.MainForm::folderMenu
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection [System.Windows.Forms]System.Windows.Forms.ToolStrip::get_Items()
        ldc.i4.0
        callvirt instance class [System.Windows.Forms]System.Windows.Forms.ToolStripItem [System.Windows.Forms]System.Windows.Forms.ToolStripItemCollection::get_Item(int32)
        ldarg.1
        ldfld string FolderMap.FolderNode::FullPath
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripItem::set_ToolTipText(string)
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip FolderMap.MainForm::folderMenu
        ldarg.2
        ldarg.3
        ldarg.s y
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.ToolStripDropDown::Show(class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ret
    }

    .method private hidebysig instance void OnMapContext(object sender, class [System.Windows.Forms]System.Windows.Forms.MouseEventArgs e) cil managed
    {
        .maxstack 5
        ldarg.0
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldfld class FolderMap.Tile FolderMap.TreemapView::ContextTile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldarg.2
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_X()
        ldarg.2
        callvirt instance int32 [System.Windows.Forms]System.Windows.Forms.MouseEventArgs::get_Y()
        call instance void FolderMap.MainForm::ShowFolderMenu(class FolderMap.FolderNode, class [System.Windows.Forms]System.Windows.Forms.Control, int32, int32)
        ret
    }

    .method private hidebysig instance void OnOpenInExplorer(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 5
        .locals init (
            string folderPath,
            class [mscorlib]System.Exception failure,
            string message
        )
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip FolderMap.MainForm::folderMenu
        callvirt instance object [System.Windows.Forms]System.Windows.Forms.Control::get_Tag()
        castclass [mscorlib]System.String
        stloc folderPath
        .try
        {
            ldloc folderPath
            call void FolderMap.Explorer::Open(string)
            leave DONE
        }
        catch [System]System.ComponentModel.Win32Exception
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.IO.IOException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.UnauthorizedAccessException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.Security.SecurityException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.ArgumentException
        {
            stloc failure
            leave FAILED
        }
        catch [mscorlib]System.NotSupportedException
        {
            stloc failure
            leave FAILED
        }
    FAILED:
        ldstr "Could not open in File Explorer: "
        ldloc folderPath
        ldstr "\r\n"
        ldloc failure
        callvirt instance string [mscorlib]System.Exception::get_Message()
        call string [mscorlib]System.String::Concat(string, string, string, string)
        stloc message
        ldarg.0
        ldloc message
        call instance void FolderMap.MainForm::SetStatusMessage(string)
        ldarg.0
        ldloc message
        ldstr "FolderMap - cannot open File Explorer"
        ldc.i4.0
        ldc.i4.s 16
        call valuetype [System.Windows.Forms]System.Windows.Forms.DialogResult [System.Windows.Forms]System.Windows.Forms.MessageBox::Show(class [System.Windows.Forms]System.Windows.Forms.IWin32Window, string, string, valuetype [System.Windows.Forms]System.Windows.Forms.MessageBoxButtons, valuetype [System.Windows.Forms]System.Windows.Forms.MessageBoxIcon)
        pop
    DONE:
        ret
    }

    .method private hidebysig instance void OnMapSelect(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 3
        .locals init (class FolderMap.Tile tile)
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldfld class FolderMap.Tile FolderMap.TreemapView::SelectedTile
        stloc tile
        ldarg.0
        ldloc tile
        ldfld class FolderMap.FolderNode FolderMap.Tile::Folder
        ldloc tile
        ldfld bool FolderMap.Tile::DirectFiles
        call instance void FolderMap.MainForm::SetSelectionDetails(class FolderMap.FolderNode, bool)
        ret
    }

    .method private hidebysig instance void OnMapActivate(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 2
        ldarg.0
        ldarg.0
        ldfld class FolderMap.TreemapView FolderMap.MainForm::map
        ldfld class FolderMap.FolderNode FolderMap.TreemapView::ActivatedFolder
        call instance void FolderMap.MainForm::SelectFolder(class FolderMap.FolderNode)
        ret
    }

    .method private hidebysig instance void OnUp(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 2
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.MainForm::CurrentFolder
        brfalse DONE
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.MainForm::CurrentFolder
        ldfld class FolderMap.FolderNode FolderMap.FolderNode::Parent
        brfalse DONE
        ldarg.0
        ldarg.0
        ldfld class FolderMap.FolderNode FolderMap.MainForm::CurrentFolder
        ldfld class FolderMap.FolderNode FolderMap.FolderNode::Parent
        call instance void FolderMap.MainForm::SelectFolder(class FolderMap.FolderNode)
    DONE:
        ret
    }

    .method private hidebysig instance void OnIssues(object sender, class [mscorlib]System.EventArgs e) cil managed
    {
        .maxstack 5
        .locals init (
            class [System.Windows.Forms]System.Windows.Forms.Form dialog,
            class [System.Windows.Forms]System.Windows.Forms.TextBox details
        )
        newobj instance void [System.Windows.Forms]System.Windows.Forms.Form::.ctor()
        stloc dialog
        .try
        {
            ldloc dialog
            ldstr "FolderMap - skipped entries and scan errors"
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
            ldloc dialog
            ldc.i4 900
            ldc.i4 480
            newobj instance void [System.Drawing]System.Drawing.Size::.ctor(int32, int32)
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.Form::set_ClientSize(valuetype [System.Drawing]System.Drawing.Size)
            ldloc dialog
            ldc.i4.4
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.Form::set_StartPosition(valuetype [System.Windows.Forms]System.Windows.Forms.FormStartPosition)
            ldloc dialog
            ldc.i4.0
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.Form::set_ShowInTaskbar(bool)
            ldloc dialog
            ldarg.0
            ldfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::bodyFont
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Font(class [System.Drawing]System.Drawing.Font)
            newobj instance void [System.Windows.Forms]System.Windows.Forms.TextBox::.ctor()
            stloc details
            ldloc details
            ldc.i4.1
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.TextBoxBase::set_Multiline(bool)
            ldloc details
            ldc.i4.1
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.TextBoxBase::set_ReadOnly(bool)
            ldloc details
            ldc.i4.0
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.TextBoxBase::set_WordWrap(bool)
            ldloc details
            ldc.i4.3
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.TextBox::set_ScrollBars(valuetype [System.Windows.Forms]System.Windows.Forms.ScrollBars)
            ldloc details
            ldc.i4.5
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Dock(valuetype [System.Windows.Forms]System.Windows.Forms.DockStyle)
            ldloc details
            ldarg.0
            ldfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
            ldfld int32 FolderMap.ScanResult::IssueCount
            conv.i8
            call string FolderMap.Display::Number(int64)
            ldstr " skipped / unreadable entries. Showing the first 200 diagnostics.\r\nThese entries contribute no bytes; affected folder totals are marked partial.\r\n\r\n"
            call string [mscorlib]System.String::Concat(string, string)
            call string [mscorlib]System.Environment::get_NewLine()
            ldarg.0
            ldfld class FolderMap.ScanResult FolderMap.MainForm::LastResult
            ldfld class [mscorlib]System.Collections.Generic.List`1<string> FolderMap.ScanResult::Issues
            callvirt instance !0[] class [mscorlib]System.Collections.Generic.List`1<string>::ToArray()
            call string [mscorlib]System.String::Join(string, string[])
            call string [mscorlib]System.String::Concat(string, string)
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.Control::set_Text(string)
            ldloc dialog
            ldloc details
            call void FolderMap.Ui::Add(class [System.Windows.Forms]System.Windows.Forms.Control, class [System.Windows.Forms]System.Windows.Forms.Control)
            ldloc details
            ldc.i4.0
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.TextBoxBase::set_SelectionStart(int32)
            ldloc details
            ldc.i4.0
            callvirt instance void [System.Windows.Forms]System.Windows.Forms.TextBoxBase::set_SelectionLength(int32)
            ldloc dialog
            ldarg.0
            callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.DialogResult [System.Windows.Forms]System.Windows.Forms.Form::ShowDialog(class [System.Windows.Forms]System.Windows.Forms.IWin32Window)
            pop
            leave DONE
        }
        finally
        {
            ldloc dialog
            callvirt instance void [System]System.ComponentModel.Component::Dispose()
            endfinally
        }
    DONE:
        ret
    }

    .method family hidebysig virtual instance void OnKeyDown(class [System.Windows.Forms]System.Windows.Forms.KeyEventArgs e) cil managed
    {
        .maxstack 3
        ldarg.1
        callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.Keys [System.Windows.Forms]System.Windows.Forms.KeyEventArgs::get_KeyCode()
        ldc.i4 116
        bne.un CHECK_ESCAPE
        ldarg.0
        call instance void FolderMap.MainForm::StartScan()
        br HANDLED
    CHECK_ESCAPE:
        ldarg.1
        callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.Keys [System.Windows.Forms]System.Windows.Forms.KeyEventArgs::get_KeyCode()
        ldc.i4.s 27
        bne.un CHECK_UP
        ldarg.0
        call instance bool FolderMap.MainForm::IsScanning()
        brfalse BASE
        ldarg.0
        call instance void FolderMap.MainForm::CancelScan()
        br HANDLED
    CHECK_UP:
        ldarg.1
        callvirt instance bool [System.Windows.Forms]System.Windows.Forms.KeyEventArgs::get_Alt()
        brfalse BASE
        ldarg.1
        callvirt instance valuetype [System.Windows.Forms]System.Windows.Forms.Keys [System.Windows.Forms]System.Windows.Forms.KeyEventArgs::get_KeyCode()
        ldc.i4.s 38
        bne.un BASE
        ldarg.0
        ldarg.0
        ldsfld class [mscorlib]System.EventArgs [mscorlib]System.EventArgs::Empty
        call instance void FolderMap.MainForm::OnUp(object, class [mscorlib]System.EventArgs)
    HANDLED:
        ldarg.1
        ldc.i4.1
        callvirt instance void [System.Windows.Forms]System.Windows.Forms.KeyEventArgs::set_SuppressKeyPress(bool)
    BASE:
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Control::OnKeyDown(class [System.Windows.Forms]System.Windows.Forms.KeyEventArgs)
        ret
    }

    .method family hidebysig virtual instance void OnFormClosing(class [System.Windows.Forms]System.Windows.Forms.FormClosingEventArgs e) cil managed
    {
        .maxstack 2
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Form::OnFormClosing(class [System.Windows.Forms]System.Windows.Forms.FormClosingEventArgs)
        ldarg.1
        callvirt instance bool [System]System.ComponentModel.CancelEventArgs::get_Cancel()
        brtrue DONE
        ldarg.0
        ldc.i4.1
        stfld bool FolderMap.MainForm::closing
        ldarg.0
        call instance bool FolderMap.MainForm::IsScanning()
        brfalse DONE
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::CancelAsync()
    DONE:
        ret
    }

    .method family hidebysig virtual instance void Dispose(bool disposing) cil managed
    {
        .maxstack 2
        ldarg.1
        brfalse BASE
        ldarg.0
        ldfld class [System]System.Diagnostics.Stopwatch FolderMap.MainForm::scanClock
        brfalse CLOCK_STOPPED
        ldarg.0
        ldfld class [System]System.Diagnostics.Stopwatch FolderMap.MainForm::scanClock
        callvirt instance void [System]System.Diagnostics.Stopwatch::Stop()
    CLOCK_STOPPED:
        ldarg.0
        ldc.i4.1
        stfld bool FolderMap.MainForm::closing
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip FolderMap.MainForm::folderMenu
        brfalse DISPOSE_WORKER_CHECK
        ldarg.0
        ldfld class [System.Windows.Forms]System.Windows.Forms.ContextMenuStrip FolderMap.MainForm::folderMenu
        callvirt instance void [System]System.ComponentModel.Component::Dispose()
    DISPOSE_WORKER_CHECK:
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        brfalse BASE
        ldarg.0
        call instance bool FolderMap.MainForm::IsScanning()
        brfalse DISPOSE_WORKER
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        callvirt instance void [System]System.ComponentModel.BackgroundWorker::CancelAsync()
    DISPOSE_WORKER:
        ldarg.0
        ldfld class [System]System.ComponentModel.BackgroundWorker FolderMap.MainForm::worker
        callvirt instance void [System]System.ComponentModel.Component::Dispose()
    BASE:
        ldarg.0
        ldarg.1
        call instance void [System.Windows.Forms]System.Windows.Forms.Form::Dispose(bool)
        ldarg.1
        brfalse DONE
        ldarg.0
        ldfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::bodyFont
        brfalse DONE
        ldarg.0
        ldfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::bodyFont
        callvirt instance void [System.Drawing]System.Drawing.Font::Dispose()
        ldarg.0
        ldfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::titleFont
        callvirt instance void [System.Drawing]System.Drawing.Font::Dispose()
        ldarg.0
        ldfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::pathFont
        callvirt instance void [System.Drawing]System.Drawing.Font::Dispose()
        ldarg.0
        ldnull
        stfld class [System.Drawing]System.Drawing.Font FolderMap.MainForm::bodyFont
    DONE:
        ret
    }
}
