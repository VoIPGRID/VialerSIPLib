//
//  Message.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//


enum Message {

    case feature(Feature)
    
    enum Feature {
        case userHandling(UserHandling)
        case settings(Settings)
        case calling(Calling)
        
        enum UserHandling {
            case useCase(UseCase)
            
            enum UseCase {
                case login(LogIn)
                case logout(LogOut)
                
                enum LogIn {
                    case action(Action)
                    
                    enum Action {
                        case logIn(String, String) // logIn(username, password)
                        case logInConfirmed(User)
                    }
                }
                
                enum LogOut {
                    case action(Action)
                    
                    enum Action {
                        case logOut(User)
                        case logOutConfirmed(User)
                    }
                }
            }
        }
        
        enum Settings {
            case useCase(UseCase)
            
            enum UseCase {
                case transport(Transport)
                case register(Register)
                case unregister(Unregister)
            }
            
            enum Transport {
                case action(Action)
                
                enum Action {
                    case activate(TransportOption)
                    case didActivate(TransportOption)
                }
            }
            
            enum Register{}
            enum Unregister{}
        }
        
        enum Calling {
            case useCase(UseCase)
            
            enum UseCase {
                case call(Calling)
                
                enum Calling {
                    case action(Action)
                    
                    enum Action {
                        case start(String)
                        case callDidStart(Call)
                        case failedToStartCall(Call)
                        case stop(Call)
                        case callDidStop(Call)
                    }
                }
            }
        }
    }
}

extension Message.Feature.Calling.UseCase.Calling.Action: Equatable {

    static func == (
        lhs: Message.Feature.Calling.UseCase.Calling.Action,
        rhs: Message.Feature.Calling.UseCase.Calling.Action
    ) -> Bool
    {
        let compare: (Call, Call) -> Bool = { $0.uuid == $1.uuid }
        
        switch (lhs, rhs) {
        case (            .start,                          .start)             : return true
        case (     .callDidStart(let lhsCall),      .callDidStart(let rhsCall)): return compare(lhsCall, rhsCall)
        case (             .stop(let lhsCall),              .stop(let rhsCall)): return compare(lhsCall, rhsCall)
        case (      .callDidStop(let lhsCall),       .callDidStop(let rhsCall)): return compare(lhsCall, rhsCall)
        case (.failedToStartCall(let lhsCall), .failedToStartCall(let rhsCall)): return compare(lhsCall, rhsCall)
        default:
            return false
        }
    }
}
