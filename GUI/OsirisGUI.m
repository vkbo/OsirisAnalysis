function varargout = OsirisGUI(varargin)
% OSIRISGUI MATLAB code for OsirisGUI.fig
%      OSIRISGUI, by itself, creates a new OSIRISGUI or raises the existing
%      singleton*.
%
%      H = OSIRISGUI returns the handle to a new OSIRISGUI or the handle to
%      the existing singleton*.
%
%      OSIRISGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OSIRISGUI.M with the given input arguments.
%
%      OSIRISGUI('Property','Value',...) creates a new OSIRISGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OsirisGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OsirisGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OsirisGUI

% Last Modified by GUIDE v2.5 12-Dec-2014 18:22:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OsirisGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @OsirisGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before OsirisGUI is made visible.
function OsirisGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to OsirisGUI (see VARARGIN)

handles.Data = OsirisData;

% Choose default command line output for OsirisGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes OsirisGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = OsirisGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% Executes on button press in btnDataBrowse.
function btnDataBrowse_Callback(hObject, eventdata, handles)

    sPath = uigetdir;
    set(handles.txtDataPath, 'String', sPath);


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over btnDataBrowse.
function btnDataBrowse_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to btnDataBrowse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function txtDataPath_Callback(hObject, eventdata, handles)
% hObject    handle to txtDataPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtDataPath as text
%        str2double(get(hObject,'String')) returns contents of txtDataPath as a double


% --- Executes during object creation, after setting all properties.
function txtDataPath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtDataPath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Executes on button press in btnLoadData.
function btnLoadData_Callback(hObject, eventdata, handles)

    % Load dataset
    handles.Data.Path = get(handles.txtDataPath, 'String');
    
    % Get info
    sCoords = handles.Data.Config.Variables.Simulation.Coordinates;
    iDim    = handles.Data.Config.Variables.Simulation.Dimensions;
    
    sGeometry = sprintf('%s%s %dD', upper(sCoords(1)), lower(sCoords(2:end)), iDim);

    set(handles.infGeometry, 'String', sGeometry);

    guidata(hObject, handles);


% --- Executes on button press in btnDensity.
function btnDensity_Callback(hObject, eventdata, handles)
% hObject    handle to btnDensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of btnDensity
    iVal = get(hObject, 'Value');
    
    
    
    
    
    
