unit Core.Exceptions;

interface

uses
  System.SysUtils;

type
  ECoreValidatorError = class(Exception);
  ESQLMakerError = class(Exception);
  EDataBaseDAOError = class(Exception);

  EEmailAuthError = class(Exception);
  EEmailFromAddresError = class(Exception);
  EEmailToAddresError = class(Exception);


implementation

end.
