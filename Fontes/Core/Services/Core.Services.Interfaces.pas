unit Core.Services.Interfaces;

interface

uses
   Horse
  ,System.JSON;

type
  IController = interface
    ['{1173182C-A2D3-4ADB-94D4-CFF10F6A43B0}']
    procedure DoPost(Req: THorseRequest; Res: THorseResponse);
    procedure DoGet(Req: THorseRequest; Res: THorseResponse);
  end;

  IService = interface
    ['{DED15482-CD08-45A7-90D3-68787E2E6771}']
    function GetService(const id: Integer): String;
    function GetServices(): String;

    function PostService(const ABody: TJSONObject): String;
  end;

implementation

end.
